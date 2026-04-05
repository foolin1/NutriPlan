import Foundation

protocol FoodRepository {
    func getAllFoods() -> [Food]
    func getFoodsById() -> [String: Food]
    func getFood(by id: String) -> Food?
}
