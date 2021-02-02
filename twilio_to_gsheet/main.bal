import ballerina/websub;
import ballerina/stringutils;
import ballerina/config;
import ballerina/encoding;
import ballerina/lang.'int as ints;
import ballerina/log;
import ballerinax/twilio.webhook as webhook;
import ballerinax/googleapis_sheets as sheets;

string port = config:getAsString("PORT");
int PORT = check ints:fromString(port);

listener webhook:TwilioWebhookListener twilioListener = new (PORT);

sheets:SpreadsheetConfiguration spreadsheetConfig = {oauth2Config: {
        accessToken: config:getAsString("ACCESS_TOKEN"),
        refreshConfig: {
            clientId: config:getAsString("CLIENT_ID"),
            clientSecret: config:getAsString("CLIENT_SECRET"),
            refreshUrl: config:getAsString("REFRESH_URL"),
            refreshToken: config:getAsString("REFRESH_TOKEN")
        }
    }};

sheets:Client spreadsheetClient = new (spreadsheetConfig);

@websub:SubscriberServiceConfig {subscribeOnStartUp: false}
service websub:SubscriberService /twilio on twilioListener {

    remote function onNotification(websub:Notification notification) returns @tainted error? {
        log:print(notification.getHeader("X-Twilio-Signature"));
        webhook:TwilioEvent payload = check twilioListener.getEventType(notification);

        // Check whethe the incoming payload is a IncomingSmsEvent and its status
        if (payload is webhook:IncomingSmsEvent && (payload.SmsStatus == webhook:RECEIVED)) {
            sheets:Spreadsheet spreadsheet = check spreadsheetClient->openSpreadsheetById(config:getAsString("SPREADSHEET_ID"));
            sheets:Sheet sheet = check spreadsheet.getSheetByName(config:getAsString("SHEET_NAME"));
            string? messageBody = payload?.Body;

            if (messageBody is string) {
                var decodedMessageBody = check encoding:decodeUriComponent(messageBody, "UTF-8");
                string[] messageBodyParts = stringutils:split(decodedMessageBody, " ");
                string languageToVote = messageBodyParts[1];
                
                // Get the values of the column A which contains the language list where the users vote.
                var languageList = check sheet->getColumn("A");

                // Traverse through the language list and increment the vote count of the language sent by the user.
                foreach var row in 1 ... languageList.length() {
                    var rowValue = languageList[row - 1];

                    if ((rowValue is string) && stringutils:equalsIgnoreCase(rowValue, languageToVote)) {
                        var rowData = check sheet->getRow(row);
                        int currentVoteCount = check ints:fromString(<string>rowData[1]);
                        string cellNumber = string `B${row}`;
                        (string|int)[] values = [languageToVote, currentVoteCount + 1];
                        var appendResult = check sheet->setCell(cellNumber, <@untainted>currentVoteCount + 1);
                        log:print("success");
                    }

                }

            }
        }
    }

}
