import UIKit
import CoreData

class FavoritesScreenViewController: UIViewController {
    
    // MARK: - Properties
    var favoritesList: CDFavoritesList?
    
    // UI Components
    private let favoritesTable = UITableView()
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Favorites" // Set the title for this view
        view.backgroundColor = .systemBackground
        view.addSubview(favoritesTable)
        
        // Setup the table view
        setupFavoritesTable()
        
        // Fetch and display the list of favorite movies
        fetchFavoritesList()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Reload the table data whenever the view reappears
        favoritesTable.reloadData()
    }
    
    // MARK: - TableView Setup
    private func setupFavoritesTable() {
        // Configure table view properties
        favoritesTable.dataSource = self
        favoritesTable.delegate = self
        favoritesTable.register(CustomTableCell.self, forCellReuseIdentifier: CustomTableCell.ID)
        favoritesTable.rowHeight = 120
        favoritesTable.allowsSelection = true
        
        // Set up Auto Layout constraints for the table view
        favoritesTable.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            favoritesTable.topAnchor.constraint(equalTo: self.view.layoutMarginsGuide.topAnchor),
            favoritesTable.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            favoritesTable.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            favoritesTable.rightAnchor.constraint(equalTo: self.view.rightAnchor)
        ])
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate Methods
extension FavoritesScreenViewController: UITableViewDataSource, UITableViewDelegate {
    
    // Number of rows in the table view (equal to the number of favorite movies)
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return favoritesList?.moviesArray.count ?? 0
    }
    
    // Configure and return each cell for the table view
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = favoritesTable.dequeueReusableCell(withIdentifier: CustomTableCell.ID) as! CustomTableCell
        
        if let favoritesList = favoritesList {
            // Set up the cell with the movie data
            cell.set(CDMovie: favoritesList.moviesArray[indexPath.row])
        }
        return cell
    }
    
    // Handle row selection (navigate to movie details screen)
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let favoritesList = favoritesList {
            let movieTitle = favoritesList.moviesArray[indexPath.row].titleUnwrapped
            let movieYear = favoritesList.moviesArray[indexPath.row].yearUnwrapped
            Task {
                // Fetch the movie details asynchronously
                if let movie = await fetchMovie(title: movieTitle, year: movieYear) {
                    // Navigate to the movie details screen
                    navigationController?.pushViewController(MovieDetailsScreenViewController(movie: movie), animated: true)
                }
            }
        }
    }
    
    // Enable swipe-to-delete functionality for each row
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // Handle row deletion (remove the movie from favorites)
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            removeFromFavorites(atIndex: indexPath.row)
        }
    }
}

// MARK: - Core Data Operations
extension FavoritesScreenViewController {
    
    // Fetch the favorites list from Core Data
    func fetchFavoritesList() {
        Task {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                print("Error in getting appDelegate for Core Data fetch")
                return
            }
            
            let context = appDelegate.persistentContainer.viewContext // Get Core Data context
            let favoritesListFetchRequest = NSFetchRequest<CDFavoritesList>(entityName: "CDFavoritesList")
            
            // Attempt to fetch the favorites list from Core Data
            do {
                if let fetchedFavorites = try context.fetch(favoritesListFetchRequest).first {
                    favoritesList = fetchedFavorites
                } else {
                    print("Could not find favorites list, creating a new one.")
                    favoritesList = CDFavoritesList(context: context)
                }
                
                // Reload the table view to reflect the fetched data
                favoritesTable.reloadData()
            } catch let error as NSError {
                print("Error fetching favorites list: \(error), \(error.userInfo)")
            }
        }
    }
    
    // Remove a movie from the favorites list in Core Data
    func removeFromFavorites(atIndex index: Int) {
        Task {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                print("Error in getting appDelegate for Core Data remove operation")
                return
            }
            
            let context = appDelegate.persistentContainer.viewContext // Get Core Data context
            
            // Retrieve the movie to be deleted from the favorites list
            guard let movieToDelete = favoritesList?.moviesArray[index] else {
                print("Error finding movie to delete")
                return
            }
            
            // Delete the movie from Core Data
            context.delete(movieToDelete)
            do {
                try context.save() // Save the changes to Core Data
            } catch let error as NSError {
                print("Error saving data after deletion: \(error), \(error.userInfo)")
            }
            
            // Reload the table view to reflect the updated favorites list
            favoritesTable.reloadData()
        }
    }
}
