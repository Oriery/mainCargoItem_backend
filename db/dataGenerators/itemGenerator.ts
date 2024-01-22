import Papa from "papaparse";
import fs from "fs";

let globalItemId = 1000000;
const ITEMCLASS_BY_DEPTH: { [maxDepth: number]: number[] } = {
  0: [0, 1, 2, 3],
  1: [6, 7, 8],
  2: [4, 5],
  3: [1000, 1001, 1002],
};

type GeneratedItem = {
  id: number;
  class_id: number;
  containedIn_id: number | null;
  fromLocation_id: number;
  toLocation_id: number;
};

const TRANSPORT_COUNT = 2;

type Transport2RootItem = {
  transport_id: number;
  item_id: number;
};

const POSSIBLE_LOCATIONS = [1, 2, 3, 4, 5, 6, 7, 8];

const generatedItems: GeneratedItem[] = [];

const TOP_LEVEL_ITEM_COUNT_PER_TRANSPORT = 400;
const CONTAINED_OBJECTS_PER_ITEM = 20;
const MAX_DEPTH = 3;
const PROBABILITY_OF_ITEM_GOING_TO_ANOTHER_LOCATION_THAN_PARENT = 0.02;

function generateItem(
  depth: number,
  parent_id: number | null,
  parentFromLocation_id: number,
  parentToLocation_id: number
): number {
  const id = globalItemId++;

  const class_id =
    ITEMCLASS_BY_DEPTH[depth][
      Math.floor(Math.random() * ITEMCLASS_BY_DEPTH[depth].length)
    ];
  const containedIn_id = parent_id;

  let fromLocation_id = parentFromLocation_id;
  let toLocation_id = parentToLocation_id;
  if (
    Math.random() < PROBABILITY_OF_ITEM_GOING_TO_ANOTHER_LOCATION_THAN_PARENT
  ) {
    while (
      fromLocation_id === parentFromLocation_id &&
      toLocation_id === parentToLocation_id
    ) {
      fromLocation_id =
        POSSIBLE_LOCATIONS[
          Math.floor(Math.random() * POSSIBLE_LOCATIONS.length)
        ];
      toLocation_id =
        POSSIBLE_LOCATIONS[
          Math.floor(Math.random() * POSSIBLE_LOCATIONS.length)
        ];
    }
  }

  const newItem = {
    id,
    class_id,
    containedIn_id,
    fromLocation_id,
    toLocation_id,
  };

  generatedItems.push(newItem);

  if (depth < MAX_DEPTH) {
    for (let i = 0; i < CONTAINED_OBJECTS_PER_ITEM; i++) {
      generateItem(depth + 1, id, fromLocation_id, toLocation_id);
    }
  }

  return id;
}

const transport2RootItems: Transport2RootItem[] = [];

for (let transport_id = 0; transport_id < TRANSPORT_COUNT; transport_id++) {
  for (let i = 0; i < TOP_LEVEL_ITEM_COUNT_PER_TRANSPORT; i++) {
    console.log(`Generating root item ${i} for transport ${transport_id}`);
    const item_id = generateItem(0, null, 1, 2);

    transport2RootItems.push({
      transport_id,
      item_id,
    });
  }
}

const csv = Papa.unparse(generatedItems, { delimiter: ";" });
fs.writeFileSync("db/csv/oriery.mci-Item.csv", csv);

const csv_transport2RootItems = Papa.unparse(transport2RootItems, {
  delimiter: ";",
});
fs.writeFileSync(
  "db/csv/oriery.mci-Transport2RootItem.csv",
  csv_transport2RootItems
);
