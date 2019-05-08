part of mqtt_im_client;

class Action {
  db.Database _database;
  
  Action(this._database);

  static Handler<ActionHandle, void> open(DatabaseConfig config) {
    return ActionFactory.getOpenHandler(config);
  }

  static Handler<ActionHandle, void> delete(String dbName){
    return ActionFactory.getDeleteHandler(dbName);
  }

  Handler<ActionHandle, void> close(){
    return ActionFactory.getCloseHandler(this._database);
  }

  Handler<FindHandle, void> find(List<ImTopic> imTopics, int number){
    return ActionFactory.getFindHandler(this._database, imTopics, number);
  }

  Handler<FindOneHandle, void> findOne(ImTopic imTopic, int number, int time){
    return ActionFactory.getFindOneHandler(this._database, imTopic, number, time);
  }

  Handler<ActionHandle, void> add(ImTopic imTopic, ImMessage imMessage){
    return ActionFactory.getAddHandler(this._database, imTopic, imMessage);
  }

  Handler<ActionHandle, void> remove(ImTopic imTopic, int keepMessageNumber){
    return ActionFactory.getRemoveHandler(this._database, imTopic, keepMessageNumber);
  }
}