# Twilio to Twilio - Forward the SMS recieve to a twilio number to a local mobile number
<div style="text-align:center"><img src="./docs/resources/twilio_twilio_template_overview.jpg" alt="Twilio-Twilio Integration template overview"/></div>

## Integration Use Case
This integration template listens to the incoming SMS to a Twilio Number and forward that to a given mobile number as a SMS.

## Pre-requisites
- [Ballerina Distribution](https://ballerina.io/learn/getting-started/)
- A Text Editor or an IDE ([VSCode](https://marketplace.visualstudio.com/items?itemName=ballerina.ballerina), 
[IntelliJ IDEA](https://plugins.jetbrains.com/plugin/9520-ballerina)). 
- Google Cloud Platform Account
- Twilio Connector and Google Calender connector, which will be downloaded from Ballerina Central during the build process.

## Configuring the Integration Template
Create a Google Google Cloud Platform (GCP) account and log into the [developer console](https://console.cloud.google.com/).

- Setup an OAuth App and get client ID and client secret credentials
- Further obtain Access Token and Refresh Token, and Refresh Token URL 
- Create a Google sheet and get its ID and Sheet name.
- Insert set of Languages(to the fist column of the sheet) which we want to put forward in the survey to get user votes

Once you obtained all configurations, Replace "" in the `ballerina.conf` file with your data.

##### ballerina.conf
```
PORT = 
ACCOUNT_SID=""
AUTH_TOKEN=""
STATUS_CALLBACK_URL=""

```
## Webhook Callback URL registration
- Use ngrok and obtain a proxy URL.
- Add it under the incoming message webhook URL under your twilio number in the [twilio dashboard]. 
