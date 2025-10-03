extends Node


## Example of resource_path: $SomeNode/SomeNode/MeshInstance3D.surface_material_override/0.albedo_color
## Returns [resource_value : Variant, Error]
func get_resource(from : Node, resource_path : String, method : String = 'call_method') -> Array:
	if '$' in resource_path:
		if '.' in resource_path:
			return get_resource(from.get_node(resource_path.substr(1).get_slice('.', 0)), resource_path.substr(resource_path.find('.')+1), method)
		else:
			if from.has_node(resource_path.substr(1)):
				return [from.get_node(resource_path.substr(1)), OK]
			else:
				return [null, ERR_DOES_NOT_EXIST]
	else:
		var resource = from
		if method == 'call_method':
			for property in resource_path.split('.'):
				if not '/' in property:
					if property in resource:
						resource = resource.get(property)
					else:
						return [null, ERR_DOES_NOT_EXIST]
				else:
					if resource.has_method('get_'+property.split('/')[0]):
						resource = resource.call('get_'+property.split('/')[0], int(property.split('/')[1]))
					else:
						var all_possible_method_names = permutation_sep(property.split('/')[0].split('_'), '_')
						var has = false
						for method_name in all_possible_method_names:
							if resource.has_method('get_'+method_name):
								has = true
								resource = resource.call('get_'+method_name, int(property.split('/')[1]))
						if not has:
							return [null, ERR_DOES_NOT_EXIST]
		else:
			return [null, FAILED]
		return [resource, OK]

## Example of resource_path: $SomeNode/SomeNode/MeshInstance3D.surface_material_override/0.albedo_color
## Returns Error
func set_resource(from : Node, resource_path : String, value : Variant,  method : String = 'call_method') -> Error:
	if method == 'call_method':
		if '$' in resource_path:
			if '.' in resource_path:
				return set_resource(from.get_node(resource_path.substr(1).get_slice('.', 0)), resource_path.substr(resource_path.find('.')+1), value, method)
			else:
				return ERR_INVALID_PARAMETER
		else:
			var resource = from
			for property in resource_path.split('.'):
				if not '/' in property:
					if not property in resource:
						return ERR_DOES_NOT_EXIST
					if not len(resource_path.split('.')) == 1:
						resource = resource.get(property)
					else:
						resource.set(property, value)
						return OK
				else:
					if not len(resource_path.split('.')) == 1:
						if resource.has_method('get_'+property.split('/')[0]):
							resource = resource.call('get_'+property.split('/')[0], int(property.split('/')[1]))
						else:
							var all_possible_method_names = permutation_sep(property.split('/')[0].split('_'), '_')
							var has = false
							for method_name in all_possible_method_names:
								if resource.has_method('get_'+method_name):
									has = true
									resource = resource.call('get_'+method_name, int(property.split('/')[1]))
							if not has:
								return ERR_DOES_NOT_EXIST
					else:
						if resource.has_method('set_'+property.split('/')[0]):
							resource = resource.call('set_'+property.split('/')[0], int(property.split('/')[1]), value if not value.has_method('duplicate') else value.duplicate(true))
							return OK
						else:
							var all_possible_method_names = permutation_sep(property.split('/')[0].split('_'), '_')
							var has = false
							for method_name in all_possible_method_names:
								if resource.has_method('set_'+method_name):
									resource = resource.call('set_'+method_name, int(property.split('/')[1]), value)
							if not has:
								return ERR_DOES_NOT_EXIST
				resource_path = resource_path.substr(resource_path.find('.')+1)
	else:
		pass
	return FAILED
		
	


## will return PackedStringArray([words_list_string, permutated_words_list1, permutated_words_list1])
func permutation_sep(words_list : PackedStringArray, separator='', _cache=0) -> PackedStringArray:
	var permutated_array = permutation(words_list)
	var result : PackedStringArray
	for array_num in range(len(permutated_array)):
		result.append('')
		for word_num in range(len(permutated_array[array_num])):
			result[array_num] += permutated_array[array_num][word_num]
			if word_num+1 != len(permutated_array[array_num]):
				result[array_num] += separator
	return result
	

## permutation will return [words_list, permutated_unique_words_list1, permutated_unique_words_list2]
func permutation(words_list: Array) -> Array:
	# Base case: if list is empty, return array with empty array
	if words_list.size() == 0:
		return [[]]
	# Base case: if list has only one word
	if words_list.size() == 1:
		return [[words_list[0]]]
	var result = []
	for i in range(words_list.size()):
		# Get current word
		var current_word = words_list[i]
		# Create a new list without the current word
		var remaining_words = words_list.duplicate()
		remaining_words.remove_at(i)
		# Recursively get all permutations of remaining words
		var permutations = permutation(remaining_words)
		# Prepend current word to each permutation
		for _permutation in permutations:
			var new_permutation = [current_word]
			new_permutation.append_array(_permutation)
			result.append(new_permutation)
	return result
	
