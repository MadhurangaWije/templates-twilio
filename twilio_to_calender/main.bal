import ballerina/websub;
import ballerina/stringutils;
import ballerina/config;
import ballerina/encoding;
import ballerina/lang.'int as ints;
import ballerina/log;
import ballerina/io;
import ballerinax/twilio.webhook as webhook;
import ballerinax/googleapis_calendar as calendar;
import ballerina/time;

string port = config:getAsString("PORT");
int PORT = check ints:fromString(port);
string calendarId = "primary";

const string TIME_FORMAT =  "yyyy-MM-dd'T'HH:mm:ssZ";

listener webhook:TwilioWebhookListener twilioListener = new (PORT);

calendar:CalendarConfiguration calendarConfig = {
        oauth2Config: {
            accessToken: config:getAsString("ACCESS_TOKEN"),
            refreshConfig: {
                clientId: config:getAsString("CLIENT_ID"),
                clientSecret: config:getAsString("CLIENT_SECRET"),
                refreshUrl: config:getAsString("REFRESH_URL"),
                refreshToken: config:getAsString("REFRESH_TOKEN")
            }
        }
    };

calendar:CalendarClient calendarClient = new (calendarConfig);

@websub:SubscriberServiceConfig {subscribeOnStartUp: false}
service websub:SubscriberService /twilio on twilioListener {

    remote function onNotification(websub:Notification notification) returns @tainted error? {
        log:print(notification.getHeader("X-Twilio-Signature"));
        webhook:TwilioEvent payload = check twilioListener.getEventType(notification);

        // Check whethe the incoming payload is a IncomingSmsEvent and its status
        if (payload is webhook:IncomingSmsEvent && (payload.SmsStatus == webhook:RECEIVED)) {
            
            string? messageBody = payload?.Body;

            if (messageBody is string) {
                var decodedMessageBody = check encoding:decodeUriComponent(messageBody, "UTF-8");
                string summery="";
                // checks whether " " exists
                 boolean isDoubleQuotedSummeryExists = stringutils:matches(decodedMessageBody, "\\s*(.*?)\\s*");
                if(isDoubleQuotedSummeryExists){
                    // extract the summery
                    int startIndex = <int>decodedMessageBody.indexOf("\"");
                    int lastIndex = <int>decodedMessageBody.lastIndexOf("\"");
                    summery = decodedMessageBody.substring(startIndex, lastIndex+1);
                    io:println(string `summery is ${summery}`);
                    string otherEventDetailString = decodedMessageBody.substring(lastIndex+1, decodedMessageBody.length());
                    io:println(string`Rest of the message body after double quotes - ${otherEventDetailString}`);
                }

                string[] messageBodyParts = stringutils:split(decodedMessageBody, "\"");
                string languageToVote = messageBodyParts[1];


                time:Time time = time:currentTime();
                string startTime = check time:format(time:addDuration(time, 0, 0, 0, 4, 0, 0, 0), TIME_FORMAT);
                string endTime = check time:format(time:addDuration(time, 0, 0, 0, 5, 0, 0, 0), TIME_FORMAT);
                io:println(startTime);
                calendar:InputEvent event = {
                    'start: {
                        dateTime: startTime
                    },
                    end: {
                        dateTime: endTime
                    },
                    summary: "summary"
                };

                calendar:CreateEventOptional optional = {
                    conferenceDataVersion: 1,
                    sendUpdates: "all",
                    supportsAttachments: false
                };

                var res =  checkpanic calendarClient->createEvent(calendarId, event);
                
               
            }
        }
    }

}
