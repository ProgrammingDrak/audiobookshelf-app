#!/usr/bin/env python3
"""Inspect the distributable, not just Gradle configuration. No device or signing key needed."""
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import zipfile

apk = Path(sys.argv[1]).resolve()
root = Path(__file__).resolve().parents[1]
tools = Path(os.environ['ANDROID_HOME']) / 'build-tools' / '35.0.0'
badging = subprocess.check_output([str(tools / 'aapt2'), 'dump', 'badging', str(apk)], text=True)
assert "package: name='com.programmingdrak.quietshelf' versionCode='1' versionName='0.1.0'" in badging
assert "application-label:'QuietShelf'" in badging
assert "targetSdkVersion:'36'" in badging
assert 'application-debuggable' not in badging
assert "launchable-activity: name='com.audiobookshelf.app.MainActivity'" in badging
tree = subprocess.check_output([str(tools / 'aapt2'), 'dump', 'xmltree', str(apk), '--file', 'AndroidManifest.xml'], text=True)
assert 'com.programmingdrak.quietshelf.fileprovider' in tree
assert 'quietshelf' in tree
checked = 0
with zipfile.ZipFile(apk) as archive:
    names = archive.namelist()
    assert not any(name.lower().endswith(('.jks', '.keystore', '.p12', '.pem')) for name in names)
    assert not any(name.endswith(('.epub', '.m4b')) for name in names)
    audio = [name for name in names if name.endswith('.mp3')]
    bell = (root / 'android/app/src/main/res/raw/bell.mp3').read_bytes()
    assert len(audio) == 1 and archive.read(audio[0]) == bell, 'Unexpected bundled audio'
    config = json.loads(archive.read('assets/capacitor.config.json'))
    assert config['appId'] == 'com.programmingdrak.quietshelf'
    assert config['appName'] == 'QuietShelf'
    assert 'url' not in config.get('server', {})
    for source in (root / 'dist').rglob('*'):
        if source.is_file() and not any(part.startswith('.') for part in source.relative_to(root / 'dist').parts):
            name = 'assets/public/' + source.relative_to(root / 'dist').as_posix()
            assert archive.read(name) == source.read_bytes(), 'Stale/missing bundled asset: ' + name
            checked += 1
    assert checked > 100
signature = subprocess.run([str(tools / 'apksigner'), 'verify', str(apk)], capture_output=True, text=True)
assert signature.returncode != 0 and 'Missing META-INF/MANIFEST.MF' in signature.stderr, signature.stderr
print(json.dumps({
    'apk': apk.name,
    'sha256': hashlib.sha256(apk.read_bytes()).hexdigest(),
    'bytes': apk.stat().st_size,
    'applicationId': 'com.programmingdrak.quietshelf',
    'versionCode': 1, 'versionName': '0.1.0', 'targetSdk': 36,
    'bundledAssetsByteMatched': checked,
    'debuggable': False, 'signed': False, 'installable': False,
    'embeddedBooksOrSigningKeys': False,
    'devicePlaybackDownloadsSync': 'not tested'
}, indent=2))
