import json
from difflib import SequenceMatcher

def levenshtein_similarity(a, b):
    return SequenceMatcher(None, a, b).ratio()

def is_duplicate(item, items, threshold=0.8):
    for existing_item in items:
        field_similarities = [
            levenshtein_similarity(str(item[field]), str(existing_item[field]))
            for field in item
            if field in existing_item
        ]
        if all(similarity > threshold for similarity in field_similarities):
            return True
    return False

def remove_duplicates(json_list, threshold=0.8):
    unique_items = []
    for item in json_list:
        if not is_duplicate(item, unique_items, threshold):
            unique_items.append(item)
    return unique_items

def deduplicate_json_list(json_list, threshold=0.8):
    deduplicated_list = remove_duplicates(json_list, float(threshold))
    return json.dumps(deduplicated_list, indent=2)
