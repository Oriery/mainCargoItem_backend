namespace oriery.mci;

entity Location {
  key id   : Integer @readonly;
      name : String(111) not null;
}

entity ItemClass {
  key id   : Integer @readonly;
      name : String(111) not null;
      type : Association to ItemType;
}

entity ItemType {
  key id   : Integer @readonly;
      name : String(111) not null;
}

entity Item {
  key id           : Integer64 @readonly;
      class        : Association to ItemClass;
      containedIn  : Association to Item;
      fromLocation : Association to Location;
      toLocation   : Association to Location;
      mci          : Association to MainCargoItem;
}

// TODO: current location/truck should be a field of Item instead of a separate entity?

entity MainCargoItem {
  key item             : Association to Item;
      status           : Association to MciStatus;
      nowTransportedBy : Association to Transport;
      nowLocatedAt     : Association to Location;
}

entity MciStatus {
  key id   : Integer @readonly;
      name : String(111) not null;
}

entity Transport2RootItem {
  key transport : Association to Transport;
  key item      : Association to Item;
}

entity Location2RootItem {
  key location : Association to Location;
  key item     : Association to Item;
}

entity Transport {
  key id       : Integer @readonly;
      // a truck is either at a location or on a route
      route    : Association to Route;
      location : Association to Location;
}

entity Route {
  key id           : Integer @readonly;
      fromLocation : Association to Location; // The very first location
      toLocation   : Association to Location; // The very last location
// can have multiple waypoints in between
}

entity Waypoint {
  key id            : Integer @readonly;
      route         : Association to Route;
      location      : Association to Location;
      sequence      : Integer;
      arrivalTime   : DateTime;
      departureTime : DateTime;
}
