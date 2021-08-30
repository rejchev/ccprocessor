import os
import json
import time
import sched

s = sched.scheduler(time.time, time.sleep)

def parse_config():
    with open(os.path.dirname(__file__) + '/config/settings.json', 'r') as cfg:
        config = json.load(cfg)

    return config


def clean():
    config = parse_config()
    print('Working dir: ' + config['path'])

    for file in os.listdir(config['path']):
        file = os.path.join(config['path'], file)
        print('Open: '+ file)
        
        with open(file, 'r') as storage_file:
            storage = json.load(storage_file)
        
        if (storage['expired'] <= int(time.time())):
            print('Remove: ' + file)
            os.remove(file)
    
    s.enter(3600, 1, clean)
    s.run()

clean()