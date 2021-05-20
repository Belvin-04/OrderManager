class Item{
  int price;
  String name;
  String id;

  Item(String name,int price,String id){
    this.name = name;
    this.price = price;
    this.id = id;
  }


  void setId(String id){
    this.id = id;
  }
  String getId(){
    return this.id;
  }

  void setName(String name){
    this.name = name;
  }
  String getName(){
    return this.name;
  }

  void setPrice(int price){
    this.price = price;
  }
  int getPrice(){
    return this.price;
  }

  Map toMap(){
    Map itemMap = Map();
    itemMap['name'] = this.name;
    itemMap['price'] = this.price;
    itemMap['id'] = this.id;
    return itemMap;
  }

  static Item toItem(Map itemMap){
    String name = itemMap['name'];
    int price = itemMap['price'];
    String id = itemMap['id'];
    return Item(name,price,id);
  }

  String toString(){
    String itemDetails = "${this.name}\n${this.price}";
    return itemDetails;
  }

}