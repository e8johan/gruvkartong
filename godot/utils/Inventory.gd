extends Node
class_name Inventory

"""
    Class representing the inventory.
    
    Keeps track of the amount of materials.
"""

var _amounts := Array()
var _names := ['Coal', 'Emerald', 'Gold', 'Iron', 'Lapis', 'Redstone', 'Stone']

signal amount_changed

func _init() -> void:
    for i in range(len(self._names)):
        self._amounts.append(0)
        
func force_update() -> void:
    """
        Forces the emission of amount_changed signals for all materials.
    """
    for name in self._names:
        emit_signal("amount_changed", name, self._amounts[_names.find(name)])

func add(name : String, amount : int = 1) -> void:
    """
        Adds amount of name to the inventory.
    """
    assert name in self._names
    assert amount > 0
    
    self._amounts[_names.find(name)] += amount
    emit_signal("amount_changed", name, self._amounts[_names.find(name)])

func can_take(amounts : Dictionary) -> bool:
    """
        Returns true if the amounts can be taken from the inventory.
    """
    var res : bool = true
    for k in amounts.keys():
        assert k in self._names
        assert amounts[k] > 0
        if self._amounts[self._names.find(k)] < amounts[k]:
            res = false
    return res

func take(amounts : Dictionary) -> bool:
    """
        Takes amounts from inventory. Returns true if successful
        
        Accepts a dictionary as input and ensures that all amounts, or none, are taken.
    """
    if can_take(amounts):
        for k in amounts.keys():
            self._amounts[self._names.find(k)] -= amounts[k]
        for k in amounts.keys():
            emit_signal("amount_changed", k, self._amounts[self._names.find(k)])
        return true
    else:
        return false
        
func amount(name : String) -> int:
    """
        Returns the amount of a given material
    """
    assert name in self._names
    return _amounts[self._names.find(name)]
