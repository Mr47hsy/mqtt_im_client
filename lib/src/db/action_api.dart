part of mqtt_im_client;

class ActionResult<T> extends Result {
  T _t;

  ActionResult(bool succeed, this._t, {Exception error}) : super(succeed, error: error);

  T get result => this._t;
}

typedef void ActionHandle(ActionResult<Action> result);

typedef void FindHandle(ActionResult<Map<String, List<ImMessage>>> result);

typedef void FindOneHandle(ActionResult<List<ImMessage>> result);

abstract class ActionFactory {
  static Handler<ActionHandle, void> getOpenHandler(DatabaseConfig config)
  => new ActionOpenHandler(config);

  static Handler<ActionHandle, void> getCloseHandler(db.Database database)
  => new ActionCloseHandler(database);

  static Handler<ActionHandle, void> getDeleteHandler(String dbName)
  => new ActionDeleteHandler(dbName);

  static Handler<FindHandle, void> getFindHandler(db.Database database, List<ImTopic> imTopics, int number)
  => new ActionFindHandler(database, imTopics, number);

  static Handler<FindOneHandle, void> getFindOneHandler(db.Database database, ImTopic imTopic, int number, int time)
  => new ActionFindOneHandler(database, imTopic, number, time);

  static Handler<ActionHandle, void> getAddHandler(db.Database database, ImTopic imTopic, ImMessage imMessage)
  => new ActionAddHandler(database, imTopic, imMessage);

  static Handler<ActionHandle, void> getRemoveHandler(db.Database database, ImTopic imTopic, int keepMessageNumber)
  => new ActionRemoveHandler(database, imTopic, keepMessageNumber);
}

class ActionOpenHandler implements Handler<ActionHandle, void> {
  DatabaseConfig _config;

  ActionOpenHandler(this._config);

  @override
  void handle(ActionHandle t) {
    // TODO: implement handle
    db.getDatabasesPath().then((path){
      db.openDatabase(pa.join(path, _config.dbName), version: _config.version,
          onConfigure: (database){
            mqtt.MqttLogger.log("Ready to open database");
            if(_config.configureFn != null) _config.configureFn(database);
          },
          onCreate: (database, version){
            mqtt.MqttLogger.log("Created database");
            //create table
            database.execute("CREATE TABLE message_local_buffer"
                " (id INTEGER PRIMARY KEY AUTOINCREMENT, topic TEXT, message TEXT, time INTEGER)");

            if(_config.createFn != null) _config.createFn(database, version);
          },
          onUpgrade: (database, oldVersion, newVersion){
            mqtt.MqttLogger.log("Upgraded database");
            if(_config.changeFn != null) _config.changeFn(database, oldVersion, newVersion);
          },
          onDowngrade: (database, oldVersion, newVersion){
            mqtt.MqttLogger.log("Degraded database");
            if(_config.changeFn != null) _config.changeFn(database, oldVersion, newVersion);
          },
          onOpen: (database){
            mqtt.MqttLogger.log("Open database");
            if(_config.openFn != null) _config.openFn(database);
          }).then((database){
        t(new ActionResult<Action>(true, new Action(database)));
      }, onError: (error){
        t(new ActionResult(false, null, error: error));
      });
    }, onError: (error){
      t(new ActionResult(false, null, error: error));
    });
  }
}

class ActionCloseHandler implements Handler<ActionHandle, void> {
  db.Database _database;

  ActionCloseHandler(this._database);

  @override
  void handle(ActionHandle t) {
    // TODO: implement handle
    if(_database.isOpen){
      _database.close().then((void v){
        t(new ActionResult(true, null));
      }, onError: (error){
        t(new ActionResult(false, null, error: error));
      });
    }
  }
}

class ActionDeleteHandler implements Handler<ActionHandle, void> {
  String _dbName;

  ActionDeleteHandler(this._dbName);

  @override
  void handle(ActionHandle t) {
    // TODO: implement handle
    db.getDatabasesPath().then((path){
      db.deleteDatabase(pa.join(path, _dbName)).then((void v){
        t(new ActionResult(true, null));
      }, onError: (error){
        t(new ActionResult(false, null, error: error));
      });
    }, onError: (error){
      t(new ActionResult(false, null, error: error));
    });
  }
}

abstract class Finder {
  Future<List<ImMessage>> find(db.Database database, ImTopic imTopic, int number, {int time}) async {
    List<dynamic> args = new List();
    StringBuffer where = new StringBuffer("topic = ?");
    args.add(imTopic.toStr());
    if(time != null){
      args.add(time);
      where.write(" AND ");
      where.write("time < ?");
    }

    List<Map<String, dynamic>> maps = await database.query("message_local_buffer", columns: ["topic", "message"],
        where: where.toString(), whereArgs: args,
        orderBy: "time DESC", limit: number);
    
    List<ImMessage> imMessages = new List();
    maps.forEach((map){
      imMessages.add(ImMessage.fromJson(map["message"]));
    });
    return imMessages;
  }
}

class ActionFindHandler extends Finder implements Handler<FindHandle, void> {
  List<ImTopic> _imTopics;
  int _number;
  db.Database _database;

  ActionFindHandler(this._database, this._imTopics, this._number);

  @override
  void handle(FindHandle t) {
    // TODO: implement handle
    _findMore().then((Map<String, List<ImMessage>> map){
      t(new ActionResult(true, map));
    }, onError: (error){
      t(new ActionResult(false, null, error: error));
    });
  }

  Future<Map<String, List<ImMessage>>> _findMore() async {
    Map<String, List<ImMessage>> map = new Map();
    for(ImTopic imTopic in _imTopics){
      map[imTopic.toStr()] = await find(_database, imTopic, _number);
    }
    return map;
  }
}

class ActionFindOneHandler extends Finder implements Handler<FindOneHandle, void> {
  ImTopic _imTopic;
  int _number;
  int _time;
  db.Database _database;

  ActionFindOneHandler(this._database, this._imTopic, this._number, this._time);

  @override
  void handle(FindOneHandle t) {
    // TODO: implement handle
    find(_database, _imTopic, _number, time: _time).then((List<ImMessage> imMessages){
      t(new ActionResult(true, imMessages));
    }, onError: (error){
      t(new ActionResult(false, null, error: error));
    });
  }
}

class ActionAddHandler implements Handler<ActionHandle, void> {
  ImTopic _imTopic;
  ImMessage _imMessage;
  db.Database _database;

  ActionAddHandler(this._database, this._imTopic, this._imMessage);

  @override
  void handle(ActionHandle t) {
    // TODO: implement handle
    _database.insert("message_local_buffer", <String, dynamic>{
      "topic" : _imTopic.toStr(),
      "message" : JsonCodec().encode(_imMessage),
      "time" : _imMessage.sendTime
    }).then((i){
      t(new ActionResult(true, null));
    }, onError: (error){
      t(new ActionResult(false, null, error: error));
    });
  }
}

class ActionRemoveHandler implements Handler<ActionHandle, void> {
  ImTopic _imTopic;
  int _keepMessageNumber;
  db.Database _database;

  ActionRemoveHandler(this._database, this._imTopic, this._keepMessageNumber);

  @override
  void handle(ActionHandle t) {
    // TODO: implement handle
    _database.rawDelete("DELETE FROM message_local_buffer WHERE ($_keepMessageNumber < "
        "(SELECT COUNT(*) FROM message_local_buffer WHERE topic = '${_imTopic.toStr()}')) AND "
        "(topic = '${_imTopic.toStr()}') AND (time = "
        "(SELECT MIN(time) FROM message_local_buffer WHERE topic = '${_imTopic.toStr()}'))").then((i){
          t(new ActionResult(true, null));
    }, onError: (error){
          t(new ActionResult(false, null, error: error));
    });
  }
}