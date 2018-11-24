//
//  BeerDetailsTableViewController.swift
//  Beerio
//
//  Created by Casper Verswijvelt on 23/11/2018.
//  Copyright © 2018 Casper Verswijvelt. All rights reserved.
//

import UIKit
import Toast_Swift

class BeerDetailsTableViewController: LoaderTableViewController {
    //Outlets
    @IBOutlet weak var addButton: UIBarButtonItem!
    @IBOutlet weak var addNoteButton: UIBarButtonItem!
    
    
    //Vars
    var beer : Beer? {
        didSet {
            if let beer = beer {
                self.addButton.isEnabled = true
                self.navigationItem.title = beer.name
                beerDetails = beer.tableLayout
                tableView.reloadData()
            }
        }
    }
    var toastStyle = ToastStyle()
    var isLocal : Bool = false 
    var beerDetails : [BeerSectionInfo] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        toastStyle.backgroundColor = .lightGray
        
        
    }
    override func viewWillAppear(_ animated: Bool) {
        self.navigationItem.rightBarButtonItems = isLocal ? [self.editButtonItem,addNoteButton] : [addButton]
    }
    
    //Data source methods
    override func numberOfSections(in tableView: UITableView) -> Int {
        return beerDetails.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return beerDetails[section].cells.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let beerCellInfo = beerDetails[indexPath.section].cells[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: beerCellInfo.cellType.rawValue, for: indexPath)
        
        // Configure the cell...
        cell.textLabel?.text = beerCellInfo.key
        cell.detailTextLabel?.text = beerCellInfo.value
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let beerSectionInfo = beerDetails[section]
        return beerSectionInfo.header
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
    }
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        if beerDetails.count > 0 && beerDetails[beerDetails.count-1].isNotes && beerDetails[beerDetails.count-1].cells.count > 0 && indexPath.section == beerDetails.count-1  {
            return true
        }
        return false
    }
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if(editingStyle == .delete) {
            guard let notesSectionIndex = getNotesSectionIndex() else {return}
            let notesSection = beerDetails[notesSectionIndex]
            
            
            if notesSection.cells.count > 0 && indexPath.section == notesSectionIndex  {
                if let beer = beer {
                    RealmController.singleton.removeNoteFromBeer(beer:beer,index:indexPath.row) {error in
                        if let error = error {
                            self.navigationController?.view.makeToast("Note could not be removed: '\(error.localizedDescription)'", duration: 4.0, position: .center, style: self.toastStyle)
                        } else {
                            self.tableView.beginUpdates()
                            self.beerDetails = beer.tableLayout
                            //Explanation for using async here:
                            // If we don't do it async, the delete animation is ugly
                            DispatchQueue.main.async {
                                if self.getNotesSectionIndex() == nil {
                                    self.tableView.deleteSections(IndexSet(arrayLiteral: notesSectionIndex), with: .fade)
                                } else {
                                    self.tableView.deleteRows(at: [indexPath], with: .automatic)
                                }
                                self.tableView.endUpdates()
                            }
                           
                        }
                    }
                }
            }
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showLabel", let destination = segue.destination as? ImageViewController, let cellIndex = tableView.indexPathForSelectedRow {
            
            destination.imageURL = self.beerDetails[cellIndex.section].cells[cellIndex.row].url
        }
    }
    
    @IBAction func addTapped(_ sender: Any) {
        let alert = UIAlertController(title: "Add to 'My Beers'", message: "Are you sure you want to add \(beer!.name) to your personal beer library?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Add", style: .default) { alert in
            if let beer = self.beer {
                RealmController.singleton.addBeer(beer: beer, shouldUpdateTable: true) {
                    error in

                    if let error = error {
                        self.navigationController?.view.makeToast("Beer could not be added: '\(error.localizedDescription)'", duration: 4.0, position: .center, style: self.toastStyle)
                    } else {
                        //There were no errors
                        self.navigationController?.view.makeToast("Beer succesfully added to your library", duration: 2.0, position: .center, style: self.toastStyle)
                    }
                    
                }
            }
        })
        self.present(alert, animated: true)
        
    }
    @IBAction func addNoteTapped(_ sender: Any) {
        let alert = UIAlertController(title: "Add a note to this beer", message: nil, preferredStyle: .alert)
        alert.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "e.g. 'This one made me puke'"
        }
        
        alert.addAction(UIAlertAction(title: "Save", style: .default){ action -> Void in
            let noteTextfield = alert.textFields![0] as UITextField
            if let beer = self.beer, let noteText = noteTextfield.text {
                RealmController.singleton.addNoteToBeer(beer: beer, text: noteText) {error in
                    if let error = error {
                        self.navigationController?.view.makeToast("Note could not be added: '\(error.localizedDescription)'", duration: 4.0, position: .center, style: self.toastStyle)
                    } else {
                        self.navigationController?.view.makeToast("Note added!", duration: 2.0, position: .center, style: self.toastStyle)
                        
                        self.tableView.beginUpdates()
                        let notesSectionIndex = self.getNotesSectionIndex()
                        self.beerDetails = beer.tableLayout
                        
                        //Determininging where we should insert a section
                        if notesSectionIndex == nil, let newNotesSectionIndex = self.getNotesSectionIndex() {
                            self.tableView.insertSections(IndexSet(arrayLiteral: newNotesSectionIndex), with: .automatic)
                        } else {
                            //We don't need to insert a new section, insert individual rows
                            let rowIndex = self.beerDetails[notesSectionIndex!].cells.count-1
                            let indexPath = IndexPath(row: rowIndex, section: notesSectionIndex!)
                            
                            self.tableView.insertRows(at: [indexPath], with: .automatic)
                        }
                        self.tableView.endUpdates()
                    }
                }
            }
            
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.present(alert, animated: true)
    }
    
    func getNotesSectionIndex() -> Int? {
        if let notesSectionIndex = beerDetails.firstIndex(where: {$0.isNotes}) {
            return notesSectionIndex
        }
        return nil
    }
    
    
    
}
