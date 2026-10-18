class PetAccessory {
  const PetAccessory(this.id, this.name, this.price);
  final String id, name;
  final int price;
}

const petAccessories = [
  PetAccessory('none', 'Just me', 0),
  PetAccessory('collar', 'Sunshine collar', 30),
  PetAccessory('bow', 'Berry bow', 45),
  PetAccessory('bandana', 'Mint bandana', 60),
  PetAccessory('crown', 'Little crown', 90),
];
