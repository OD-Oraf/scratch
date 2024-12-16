import base64
import json



def get_base64_encoding(file):
    string_bytes = file.encode('utf-8')
    base64_bytes = base64.b64encode(string_bytes)
    base64_string = base64_bytes.decode('utf-8')
    return base64_string

def convert_to_base64(file_path):
    try:
        with open(file_path, 'rb') as config_file:
            json_config = json.load(config_file)
            json_string = json.dumps(json_config)
            # print(json_string)
            config_file_base64_encoding = get_base64_encoding(json_string)
            # print(config_file_base64_encoding)
    except Exception as e:
        print(f"An error occurred: {e}")
        return None
    return config_file_base64_encoding

def get_file_path_base64_map(json_config):
    file_path_base64_map = {}

    for obj in json_config:
        file_path = obj['artifactConfig']
        encoded_file = convert_to_base64(file_path)
        file_path_base64_map[file_path] = encoded_file

    print(file_path_base64_map)
    return file_path_base64_map



def read_config_file():
    config_file_path = "config/dev/TestPartner-Config.json"
    with open(config_file_path, 'rb') as config_file:
        json_config = json.load(config_file)
        file_path_base54_map = get_file_path_base64_map(json_config)

        # Update config file with base64 encoded files
        json_config_string = json.dumps(json_config)
        for file_path, base64_encoding in file_path_base54_map.items():
            json_config_string = json_config_string.replace(file_path, base64_encoding)

        print("final file: ")
        print(json_config_string)



read_config_file()