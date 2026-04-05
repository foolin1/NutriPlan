import Foundation

protocol RecipeRepository {
    func getAllRecipes() -> [Recipe]
}
