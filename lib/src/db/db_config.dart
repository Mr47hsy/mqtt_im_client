part of mqtt_im_client;

class DatabaseConfig {
  db.OnDatabaseConfigureFn _configureFn;
  db.OnDatabaseCreateFn _createFn;
  db.OnDatabaseVersionChangeFn _changeFn;
  db.OnDatabaseOpenFn _openFn;

  String _dbName;
  int _version;

  DatabaseConfig(this._dbName, this._version);


  db.OnDatabaseConfigureFn get configureFn => this._configureFn;

  db.OnDatabaseCreateFn get createFn => this._createFn;

  db.OnDatabaseVersionChangeFn get changeFn => this._changeFn;

  db.OnDatabaseOpenFn get openFn => this._openFn;

  String get dbName => this._dbName;

  int get version => this._version;

  DatabaseConfig setConfigureFn(db.OnDatabaseConfigureFn fn){
    this._configureFn = fn;
    return this;
  }

  DatabaseConfig setCreateFn(db.OnDatabaseCreateFn fn){
    this._createFn = fn;
    return this;
  }

  DatabaseConfig setChangeFn(db.OnDatabaseVersionChangeFn fn){
    this._changeFn = fn;
    return this;
  }

  DatabaseConfig setOpenFn(db.OnDatabaseOpenFn fn){
    this._openFn = fn;
    return this;
  }

  DatabaseConfig setDBName(String dbName){
    this._dbName = dbName;
    return this;
  }

  DatabaseConfig setVersion(int version){
    this._version = version;
    return this;
  }
}