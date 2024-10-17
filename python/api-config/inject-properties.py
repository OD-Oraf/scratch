import json
import os
from jproperties import Properties

config = Properties()

with open(f'us-dev.properties', 'rb') as read_urls:
    config.load(read_urls)


flex_config_file = f'api-config.json'
with open(flex_config_file) as file:
    flex_config = json.load(file)
    flex_config_string = json.dumps(flex_config)


for i in range(0, len(config.items())):
    url = config[f'upstream{i + 1}'].data
    upstream_key = "${upstream" + str(i + 1) + "}"
    flex_config_string = flex_config_string.replace(f'{upstream_key}', url)

flex_config = json.loads(flex_config_string)

with open(flex_config_file, "w") as f:
    json.dump(flex_config, f, sort_keys=True, indent=4, separators=(',', ': '))