import re
import requests
import subprocess
import os
import shutil
from libs.masar import pack_asar
import time
import json
from pkg_resources import parse_version
import zipfile

inject_old = br"function validateString (value, name) { if (typeof value !== 'string') throw new TypeError('The \"' + name + '\" argument must be of type string. Received type ' + typeof value); }"
inject_new = br"function validateString(){};"

rootPath = os.path.dirname(__file__)

IMAGE_URL = "https://download.typora.io"#https://typora-download.oss-cn-shanghai.aliyuncs.com"  # https://download.typora.io"

TOOL = os.path.join(rootPath, "libs/innoextract.exe")
PackTOOL = os.path.join(rootPath, "libs/compiler/ISCC.exe")

RETRIEVE_DIR = os.path.join(rootPath, "packages")
os.makedirs(RETRIEVE_DIR, exist_ok=True)


def isLatestVersion():
    headers = {
        'user-agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.4844.51 Safari/537.36'
    }
    response = requests.get('https://api.github.com/repos/taozhiyu/TyProAction/tags', headers=headers)
    latestTag = json.loads(response.text)[0]["name"]

    response = requests.get('https://typora.io/releases/windows_64.json', headers=headers)
    latestVersion = json.loads(response.text)["version"]
    print(latestTag, latestVersion)
    return latestVersion if parse_version(latestTag) == parse_version(latestVersion) else ""


def downloadFile(url, path):
    fileName = url.split('/')[-1]
    r = requests.get(url)
    with open(os.path.join(path, fileName), "wb") as f:
        f.write(r.content)


def make_inject(path: str):
    inj = f"mod.require('{os.path.basename(path)}');"
    inj = inject_new + inj.encode()
    if len(inj) > len(inject_old):
        print("Too long inject")
        exit(2)
    inj = inj.ljust(len(inject_old), b" ")
    return inj


def test_inject(version: str):
    # 定义
    inject_file = os.path.join(rootPath, "libs/dump.js")
    prog = os.path.join(RETRIEVE_DIR, version, "resources/app.asar.unpacked/main.node")

    # 复制dump.js
    target = os.path.join(os.path.dirname(prog), "../node_modules/", os.path.basename(inject_file))
    shutil.copyfile(inject_file, target)

    # 植入dump
    with open(prog, "rb") as f:
        node = f.read()
    if inject_old not in node:
        assert f"Cannot find injection point in program file: {prog}"

    with open(prog, "wb") as f:
        f.write(node.replace(inject_old, make_inject(target)))

    # 运行，dump文件
    try:
        out = subprocess.check_output([os.path.join(RETRIEVE_DIR, version, 'Typora')], timeout=None)
    except subprocess.TimeoutExpired as e:
        out = e.stdout
        print('error')
    print(out)
    assert b"Inject Success" in out, f"Cannot inject@V{version}"
    print("start to build")
    # 成功dump
    # 修改（js里完成）
    # 打包
    appDir = ""
    newAppDir = os.path.join(rootPath, f"output/app{round(time.time())}")
    os.makedirs(newAppDir)
    appDir = newAppDir
    # 复制dump出来的js
    atom = os.path.join(rootPath, "../atom.js")
    shutil.move(atom, os.path.join(appDir, "atom.js"))
    # 修改并复制配置json
    package = os.path.join(os.path.dirname(prog), "../package.json")
    # 修改打包时版本号
    with open(package, "r+") as f:
        code = f.read()
        f.seek(0)
        f.truncate()
        f.write(code.replace("main.node", "atom.js"))
    shutil.copyfile(package, os.path.join(appDir, "package.json"))
    # 打包压缩
    pack_asar(appDir, os.path.join(appDir, "../app.asar"))
    # 复制asar文件到根目录
    shutil.copyfile(os.path.join(appDir, "../app.asar"), os.path.join(rootPath, "app.asar"))

    zip_file = zipfile.ZipFile(f'app-file-V{version}.zip','w')
    # 把zfile整个目录下所有内容，压缩为new.zip文件
    zip_file.write("app.asar",compress_type=zipfile.ZIP_DEFLATED)
    zip_file.close()

    # 添加回app文件夹
    shutil.copyfile(os.path.join(appDir, "../app.asar"), os.path.join(os.path.dirname(prog), "../app.asar"))
    # 打包
    with open(os.path.join(os.path.dirname(PackTOOL), "typro.iss"), "r+", encoding='gbk') as f:
        code = f.read()
        regex = r"MyAppVersion \"[\d\.]+\""
        result = re.sub(regex, "MyAppVersion \""+version+"\"", code, 0, re.MULTILINE)
        regex = r"packages\\[\d\.]+"
        result = re.sub(regex, r"packages\\"+version, result, 0, re.MULTILINE)
        f.seek(0)
        f.truncate()
        f.write(result)
    # 移除注入
    os.remove(target)

    subprocess.check_call([PackTOOL, os.path.join(os.path.dirname(PackTOOL), "typro.iss")], cwd=rootPath)

    # 分发(action实现)

    #删除垃圾
    shutil.rmtree(RETRIEVE_DIR)
    shutil.rmtree(os.path.join(rootPath, "output"))
    os.remove(os.path.join(rootPath, "app.asar"))

def download_windows(version: str) -> str:
    url = IMAGE_URL + f"/windows/typora-setup-x64-{version}.exe"
    filename = os.path.join(RETRIEVE_DIR, os.path.basename(url))
    if not os.path.exists(filename):
        downloadFile(url, RETRIEVE_DIR)
    if not os.path.exists(os.path.join(RETRIEVE_DIR, version)):
        subprocess.call([TOOL, filename], cwd=RETRIEVE_DIR, timeout=None)
        time.sleep(1)
        os.rename(os.path.join(RETRIEVE_DIR, "app"), os.path.join(RETRIEVE_DIR, version))


if __name__ == '__main__':
    v = isLatestVersion()
    if len(v) > 0:
        download_windows(v)
        test_inject(v)
