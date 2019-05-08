import 'package:flutter_test/flutter_test.dart';

import 'package:mqtt_im_client/mqtt_im_client.dart';

import 'dart:convert';

void main() {
  test("test local message buffer", (){
    Action action;
    Action.open(new DatabaseConfig("test.db", 1))
        .handle((h){
          if(h.succeed){
            action = h.result;
            h.result.find([ImTopic.fromStr("User/1")], 5)
                .handle((h){
                  if(h.succeed){
                    h.result.forEach((k,v){
                      print("$k : $v");
                    });
                  }
            });
          }
    });
    new Future.delayed(new Duration(seconds: 1), (){
      action?.add(ImTopic.fromStr("User/1"), ImMessage.fromJson("{'originTopic' : 'User/1', 'sendType': 'richText',"
          " 'sendId' : '2', 'sendContent' : '你好', 'sendTime': 126374}"))
          ?.handle((h){
            if(h.succeed){
              print("add ss");
            }
      });
    }).then((v){

    });
  });
}
