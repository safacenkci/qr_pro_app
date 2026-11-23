import os
import sys
import tempfile
from pathlib import Path

# Ayarlar modül yüklenirken okunur: uygulamayı içe aktarmadan önce ortamı hazırla.
_tmp = tempfile.mkdtemp(prefix="qrpro-test-")
os.environ["DB_PATH"] = os.path.join(_tmp, "qrpro.db")
os.environ["SERVICE_ACCOUNT_FILE"] = os.path.join(_tmp, "yok.json")
os.environ["RATE_LIMIT_PER_MINUTE"] = "1000"
os.environ["CONTACT_EMAIL"] = ""

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
