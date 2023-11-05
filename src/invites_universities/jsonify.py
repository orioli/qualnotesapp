import json

# Read the list of words from a file
with open('pilot_universities.txt', 'r') as file:
    words = file.read().splitlines()

# Generate the JSON array
json_array = json.dumps(words)

# Write the JSON array to a file
with open('output.json', 'w') as file:
    file.write(json_array)



