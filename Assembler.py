# Import Required Libraries
import os, argparse, shutil
from pathlib import Path

# Get Current Working Directory
cwd = os.path.dirname(os.path.realpath(__file__))

# Setup CLI argument requirements
parser = argparse.ArgumentParser(description='Assemble LUA files into .conf structure')
parser.add_argument('source',type=str,nargs=1,choices=[
    'DeadGunner',
    'DeadRemote',
    'DeadXS'
    ],
    help='Source Folder to pull LUA files from (i.e. DeadGunner, DeadRemote)')
parser.add_argument('--copy',action='store_true', 
    help='Create an additional copy of the .conf file somewhere locally on the machine (like the DU custom config folder)')

# Parse arguments provided
args = parser.parse_args()

# Set variables for which folder to assemble
src = args.source[0]
path = os.path.join(cwd,src)

# Mapping of Folders to .conf files
confMap = {
    'DeadGunner':'DeadGunner.conf',
    'DeadRemote':'DeadRemote.conf',
    'DeadXS':'DeadXS.conf'
}

# Setup and pull lua files
luaCode = []
yamlTemplate = ''
if 'lua' in os.listdir(path) and ('confTemplate.yaml' in os.listdir(path) or 'confTemplate.json' in os.listdir(path)):
    luaPath = os.path.join(path,'lua')
    if 'confTemplate.yaml' in os.listdir(path):
        yamlTemplate = open(os.path.join(path,'confTemplate.yaml'),'r').read()
    elif 'confTemplate.json' in os.listdir(path):
        yamlTemplate = open(os.path.join(path,'confTemplate.json'),'r').read()
    for file in os.listdir(os.path.join(path,'lua')):
        if file[-4:] == '.lua':
            luaCode.append(file)

if yamlTemplate:
    with open(os.path.join(cwd,confMap[src]),'w') as f:
        for file in luaCode:
            print('Replacing {0}'.format(file))
            lua = ''
            if 'confTemplate.yaml' in os.listdir(path):
                for line in open(os.path.join(path,'lua',file),'r').readlines():
                    lua += '  '*(len(file.split('.'))+1) + line
            elif 'confTemplate.json' in os.listdir(path):
                for line in open(os.path.join(path,'lua',file),'r').readlines():
                    lua += line.replace('\n','\\n')
            yamlTemplate = yamlTemplate.replace('{{'+file+'}}',lua)
            
        if '{{' in yamlTemplate:
            print('ERROR: Not all variables found')
            i = yamlTemplate.index('{{')
            print(yamlTemplate[i-100:i+100])
        else:
            print('SUCCESS: New config file written')
            f.write(yamlTemplate)
            f.close()

# Function to locate DU install folder
def locate():
    for item in os.listdir(os.path.join(os.environ['HOMEPATH'],'Desktop')):
        if 'dual' in item.lower():
            temp = open(os.path.join(os.environ['HOMEPATH'],'Desktop',item),'r', encoding = "ISO-8859-1").read()
    temp = temp.split('\\')
    build = []
    index = ''
    capture = False
    for item in temp:
        if 'Dual Universe' in item:
            index = temp.index(item)
    for x in range(index,0,-1):
        if temp[x][-1] == ':':
            build.append(temp[x][-2:]+'\\')
            break
        else:
            build.append(temp[x])
    final = reversed(build)
    return os.path.join(*final,'Game','data','lua','autoconf','custom')

if args.copy:
    shutil.copy(os.path.join(cwd,confMap[src]),locate())





