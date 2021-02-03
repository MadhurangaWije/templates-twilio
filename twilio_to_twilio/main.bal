import ballerina/websub;
import ballerina/config;
import ballerina/encoding;
import ballerina/lang.'int as ints;
import ballerina/log;
import ballerinax/twilio.webhook as webhook;
import ballerinax/twilio;

string port = config:getAsString("PORT");
int PORT = check ints:fromString(port);

listener webhook:TwilioWebhookListener twilioListener = new (PORT);

twilio:TwilioConfiguration twilioConfig = {
    accountSId: config:getAsString("ACCOUNT_SID"),
    authToken: config:getAsString("AUTH_TOKEN")
};

twilio:Client twilioClient = new (twilioConfig);

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

                string fromMobile = config:getAsString("SAMPLE_FROM_MOBILE");
                string toMobile = config:getAsString("SAMPLE_TO_MOBILE");

                var details = twilioClient->sendSms(fromMobile, toMobile, decodedMessageBody);
                if (details is twilio:SmsResponse) {
                    log:print(details.toBalString());
                } else {
                    log:print(details.toBalString());
                }
            }
        }
    }

}
