import ballerina/websub;
import ballerina/config;
import ballerina/encoding;
import ballerina/lang.'int as ints;
import ballerina/log;
import ballerinax/twilio.webhook as webhook;
import ballerinax/googleapis_gmail as gmail;

string port = config:getAsString("PORT");
int PORT = check ints:fromString(port);
string calendarId = "primary";


listener webhook:TwilioWebhookListener twilioListener = new (PORT);

gmail:GmailConfiguration gmailConfig = {
    oauthClientConfig: {
        accessToken: config:getAsString("ACCESS_TOKEN"),
        refreshConfig: {
            refreshUrl: gmail:REFRESH_URL,
            refreshToken: config:getAsString("REFRESH_TOKEN"),
            clientId:config:getAsString("CLIENT_ID"),
            clientSecret: config:getAsString("CLIENT_SECRET")
        }
    }
};

gmail:Client gmailClient = new (gmailConfig);

@websub:SubscriberServiceConfig {subscribeOnStartUp: false}
service websub:SubscriberService /twilio on twilioListener {

    remote function onNotification(websub:Notification notification) returns @tainted error? {
        log:print(notification.getHeader("X-Twilio-Signature"));
        webhook:TwilioEvent payload = check twilioListener.getEventType(notification);

        // Check whethe the incoming payload is a IncomingSmsEvent and its status
        if (payload is webhook:IncomingSmsEvent && (payload.SmsStatus == webhook:RECEIVED)) {
            string? messageBody = payload?.Body;
            string emailSubject = "Message recieved for the twilio number";

            if (messageBody is string) {
                var decodedMessageBody = check encoding:decodeUriComponent(messageBody, "UTF-8");
                log:print(decodedMessageBody);
                
                string recipientEmailAddress = "123kanishka@gmail.com";
                string userId = "me";

                gmail:MessageRequest messageRequest = {};
                messageRequest.recipient = recipientEmailAddress;
                messageRequest.subject = emailSubject;
                messageRequest.messageBody = decodedMessageBody;
                //Set the content type of the mail as TEXT_PLAIN or TEXT_HTML.
                messageRequest.contentType = gmail:TEXT_PLAIN;
                //Send the message.
                var sendMessageResponse = gmailClient->sendMessage(userId, messageRequest);

                if (sendMessageResponse is [string, string]) {
                    // If successful, print the message ID and thread ID.
                    [string, string][messageId, threadId] = sendMessageResponse;
                    log:print(string`Sent Message ID: ${messageId}`);
                    log:print(string `Sent Thread ID: ${threadId}`);
                } else {
                    // If unsuccessful, print the error returned.
                    log:print(string `Error: ${sendMessageResponse.toBalString()}`);
                }
               
            }
        }
    }

}
