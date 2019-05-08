part of mqtt_im_client;

abstract class ImTopic {
  String _targetId;
  
  ImTopic(this._targetId);

  static ImTopic fromStr(final String topicStr){
    if((topicStr == null) || (topicStr.isEmpty)){
      mqtt.MqttLogger.log("Error: input error topicStr");
      return null;
    }
    List<String> strs = topicStr.split("/");
    switch(_checkTopicHead(strs[0])){
      case TopicHead.SYSTEM : return new ImSystemTopic(strs[1]);
      case TopicHead.INFO : return new ImInfoTopic(strs[1]);
      case TopicHead.USER : return new ImUserTopic(strs[1]);
      default: {
        mqtt.MqttLogger.log("Error: Unable to resolve topicStr");
        return null;
      }
    }
  }

  String toStr();

  static _checkTopicHead(final String topicHeadStr){
    if(topicHeadStr == "System") return TopicHead.SYSTEM;
    else if(topicHeadStr == "Info") return TopicHead.INFO;
    else if(topicHeadStr == "User") return TopicHead.USER;
    return null;
  }

  String get targetId => this._targetId;
}

enum TopicHead {
  //系统topic头
  SYSTEM,
  //通知topic头
  INFO,
  //用户topic头
  USER
}

class ImSystemTopic extends ImTopic {
  ImSystemTopic(String targetId) : super(targetId);

  @override
  String toStr() {
    // TODO: implement toStr
    return "System/${this.targetId}";
  }
}

class ImInfoTopic extends ImTopic {
  ImInfoTopic(String targetId) : super(targetId);

  @override
  String toStr() {
    // TODO: implement toStr
    return "Info/${this.targetId}";
  }
  
}

class ImUserTopic extends ImTopic {
  ImUserTopic(String targetId) : super(targetId);

  @override
  String toStr() {
    // TODO: implement toStr
    return "User/${this.targetId}";
  }
  
}