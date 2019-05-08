part of mqtt_im_client;

abstract class ImMessage {
  ImTopic _originTopic;
  String _sendType;
  String _sendId;
  String _sendContent;
  int _sendTime;


  ImMessage({ImTopic originTopic, String sendId,
    String sendContent, int sendTime}){
    this._originTopic = originTopic;
    this._sendId = sendId;
    this._sendContent = sendContent;
    this._sendTime = sendTime;
  }

  static ImMessage fromJson(String jsonStr){
    Map json = JsonCodec().decode(jsonStr);
    
    if(!json.containsKey("sendType")){
      mqtt.MqttLogger.log("Error: can't find key sendType");
      return null;
    }

    if(json["sendType"] == "richText") return new ImRichTextMessage()
        .setOriginTopic(ImTopic.fromStr(json["originTopic"]))
        .setSendId(json["sendId"])
        .setSendContent(json["sendContent"])
        .setSendTime(json["sendTime"]);
    else if(json["sendType"] == "file") return new ImFileMessage()
        .setOriginTopic(ImTopic.fromStr(json["originTopic"]))
        .setSendId(json["sendId"])
        .setSendContent(json["sendContent"])
        .setSendTime(json["sendTime"]);
    
    mqtt.MqttLogger.log("Error: sendType Value Undefined");
    return null;
  }

  Map<String, dynamic> toJson();

  ImTopic get originTopic => this._originTopic;
  ImMessage setOriginTopic(ImTopic originTopic){
    this._originTopic = originTopic;
    return this;
  }

  String get sendId => this._sendId;
  ImMessage setSendId(String sendId){
    this._sendId = sendId;
    return this;
  }

  String get sendContent => this._sendContent;
  ImMessage setSendContent(String sendContent){
    this._sendContent = sendContent;
    return this;
  }
  
  int get sendTime => this._sendTime;
  ImMessage setSendTime(int sendTime){
    this._sendTime = sendTime;
    return this;
  }
  
  String get sendType => this._sendType;
}

class ImRichTextMessage extends ImMessage {
  static const String _RichText = "richText";
  
  ImRichTextMessage({ImTopic originTopic, String sendId,
    String sendContent, int sendTime}) : super(originTopic: originTopic, sendId: sendId,
      sendContent: sendContent, sendTime: sendTime) {
    this._sendType = _RichText;
  }

  @override
  Map<String, dynamic> toJson() => {
    "originTopic":originTopic.toStr(),
    "sendType":_RichText,
    "sendId":sendId,
    "sendContent":sendContent,
    "sendTime":sendTime,
  };

  
}

class ImFileMessage extends ImMessage {
  static const String _File = "file";

  ImFileMessage({ImTopic originTopic, String sendId,
    String sendContent, int sendTime}) : super(originTopic: originTopic, sendId: sendId,
      sendContent: sendContent, sendTime: sendTime) {
    this._sendType = _File;
  }

  @override
  Map<String, dynamic> toJson() => {
    "originTopic":originTopic,
    "sendType":_File,
    "sendId":sendId,
    "sendContent":sendContent,
    "sendTime":sendTime,
  };
}