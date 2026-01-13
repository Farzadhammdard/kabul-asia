#!/usr/bin/env bash
set -e

# تغییر کن به URL ریپو تو اگر لازم است
REMOTE_URL="https://github.com/Farzadhammdard/kabul-asia.git"
BRANCH="main"
COMMIT_MSG="chore: initial commit — Next.js frontend + Django DRF backend skeleton"

echo "ساخت ساختار پوشه‌ها..."
mkdir -p backend/backend
mkdir -p backend/api
mkdir -p frontend/components
mkdir -p frontend/lib
mkdir -p frontend/pages
mkdir -p frontend/styles

echo "نوشتن فایل‌ها..."

cat > .gitignore <<'EOF'
# Python
__pycache__/
*.py[cod]
*.pyc
*.pyo
*.pyd
venv/
env/
ENV/
.venv/

# Django
db.sqlite3
/staticfiles

# Node
node_modules/
.next/

# env files
.env
.env.local
.env.production
EOF

cat > README.md <<'EOF'
# Kabel Asia — Fullstack Starter (Next.js + Django)

این پروژه شامل:
- backend/: Django + DRF API با JWT authentication
- frontend/: Next.js app که به API وصل می‌شود

نحوه اجرا (محلی):

1) Backend
- cd backend
- python -m venv venv
- source venv/bin/activate  (Linux/macOS) یا venv\Scripts\activate (Windows)
- pip install -r requirements.txt
- python manage.py makemigrations
- python manage.py migrate
- python manage.py createsuperuser
- python manage.py runserver

2) Frontend
- cd frontend
- npm install
- ایجاد .env.local بر اساس .env.local.example
- npm run dev

نکات:
- endpoint لاگین: POST /api/token/  با body: { username, password } -> دریافت access و refresh token
- endpoint کاربر فعلی: GET /api/me/
- فاکتورها: /api/invoices/
- مخارج: /api/expenses/
- کاربرها: /api/users/ (فقط ادمین می‌تواند ایجاد/ویرایش/حذف کند)

برای تولید PDF واقعی از فاکتورها: در backend از WeasyPrint یا ReportLab استفاده کن و view مربوطه را پیاده‌سازی کن.
EOF

cat > LICENSE <<'EOF'
MIT License

Copyright (c) 2026 Farzadhammdard

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
... (standard MIT text continues)
EOF

# ---------------- backend files ----------------
cat > backend/requirements.txt <<'EOF'
django>=4.2
djangorestframework
djangorestframework-simplejwt
django-cors-headers
psycopg2-binary
EOF

cat > backend/manage.py <<'EOF'
#!/usr/bin/env python
import os
import sys

def main():
    os.environ.setdefault("DJANGO_SETTINGS_MODULE", "backend.settings")
    try:
        from django.core.management import execute_from_command_line
    except ImportError as exc:
        raise ImportError("Couldn't import Django") from exc
    execute_from_command_line(sys.argv)

if __name__ == "__main__":
    main()
EOF

touch backend/backend/__init__.py

cat > backend/backend/asgi.py <<'EOF'
import os
from django.core.asgi import get_asgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')
application = get_asgi_application()
EOF

cat > backend/backend/wsgi.py <<'EOF'
import os
from django.core.wsgi import get_wsgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')
application = get_wsgi_application()
EOF

cat > backend/backend/settings.py <<'EOF'
import os
from pathlib import Path
from datetime import timedelta

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = os.getenv("DJANGO_SECRET_KEY", "unsafe-dev-secret")
DEBUG = os.getenv("DJANGO_DEBUG", "1") == "1"
ALLOWED_HOSTS = ["*"]

INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "rest_framework",
    "corsheaders",
    "api",
]

MIDDLEWARE = [
    "corsheaders.middleware.CorsMiddleware",
    "django.middleware.security.SecurityMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
]

ROOT_URLCONF = "backend.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [],
        "APP_DIRS": True,
        "OPTIONS": {"context_processors": ["django.template.context_processors.debug","django.template.context_processors.request","django.contrib.auth.context_processors.auth","django.contrib.messages.context_processors.messages"],},
    },
]

WSGI_APPLICATION = "backend.wsgi.application"

DATABASES = {
    "default": {
        "ENGINE": os.getenv("DB_ENGINE", "django.db.backends.sqlite3"),
        "NAME": os.getenv("DB_NAME", BASE_DIR / "db.sqlite3"),
    }
}

AUTH_PASSWORD_VALIDATORS = []

LANGUAGE_CODE = "fa"
TIME_ZONE = "Asia/Kabul"
USE_I18N = True
USE_TZ = True

STATIC_URL = "/static/"

# CORS
CORS_ALLOW_ALL_ORIGINS = True

REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": (
        "rest_framework_simplejwt.authentication.JWTAuthentication",
    ),
    "DEFAULT_PERMISSION_CLASSES": (
        "rest_framework.permissions.IsAuthenticated",
    ),
}

SIMPLE_JWT = {
    "ACCESS_TOKEN_LIFETIME": timedelta(minutes=int(os.getenv("ACCESS_TOKEN_MINUTES", "60"))),
    "REFRESH_TOKEN_LIFETIME": timedelta(days=7),
}
EOF

cat > backend/backend/urls.py <<'EOF'
from django.contrib import admin
from django.urls import path, include
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/", include("api.urls")),
    path("api/token/", TokenObtainPairView.as_view(), name="token_obtain_pair"),
    path("api/token/refresh/", TokenRefreshView.as_view(), name="token_refresh"),
]
EOF

cat > backend/api/apps.py <<'EOF'
from django.apps import AppConfig

class ApiConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "api"

    def ready(self):
        import api.signals
EOF

cat > backend/api/models.py <<'EOF'
from django.db import models
from django.contrib.auth.models import User

ROLE_CHOICES = (
    ("admin", "Admin"),
    ("operator", "Operator"),
    ("accountant", "Accountant"),
)

class Profile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="profile")
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default="operator")
    display_name = models.CharField(max_length=150, blank=True)

    def __str__(self):
        return f"{self.user.username} ({self.role})"

class Invoice(models.Model):
    customer = models.CharField(max_length=200)
    type = models.CharField(max_length=50)  # CNC, PVC, Cutting, Carpentry
    area = models.FloatField()
    unit_price = models.FloatField()
    discount = models.FloatField(default=0)
    total = models.FloatField()
    date = models.DateField(auto_now_add=True)
    created_by = models.ForeignKey(User, null=True, on_delete=models.SET_NULL, related_name="invoices")

    def save(self, *args, **kwargs):
        self.total = (self.area * self.unit_price) - (self.discount or 0)
        super().save(*args, **kwargs)

    def __str__(self):
        return f"Invoice #{self.id} {self.customer}"

class Expense(models.Model):
    title = models.CharField(max_length=255)
    amount = models.FloatField()
    category = models.CharField(max_length=100)
    date = models.DateField(auto_now_add=True)
    created_by = models.ForeignKey(User, null=True, on_delete=models.SET_NULL, related_name="expenses")

    def __str__(self):
        return f"{self.title} - {self.amount}"
EOF

cat > backend/api/signals.py <<'EOF'
from django.contrib.auth.models import User
from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import Profile

@receiver(post_save, sender=User)
def create_profile(sender, instance, created, **kwargs):
    if created:
        Profile.objects.create(user=instance)
EOF

cat > backend/api/admin.py <<'EOF'
from django.contrib import admin
from .models import Profile, Invoice, Expense

@admin.register(Profile)
class ProfileAdmin(admin.ModelAdmin):
    list_display = ("user", "role", "display_name")

@admin.register(Invoice)
class InvoiceAdmin(admin.ModelAdmin):
    list_display = ("id", "customer", "type", "total", "date", "created_by")

@admin.register(Expense)
class ExpenseAdmin(admin.ModelAdmin):
    list_display = ("id", "title", "amount", "category", "date", "created_by")
EOF

cat > backend/api/serializers.py <<'EOF'
from rest_framework import serializers
from django.contrib.auth.models import User
from .models import Invoice, Expense, Profile

class ProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = Profile
        fields = ("role", "display_name")

class UserSerializer(serializers.ModelSerializer):
    profile = ProfileSerializer(read_only=True)
    class Meta:
        model = User
        fields = ("id", "username", "email", "first_name", "last_name", "profile")

class InvoiceSerializer(serializers.ModelSerializer):
    created_by = UserSerializer(read_only=True)
    class Meta:
        model = Invoice
        fields = ("id","customer","type","area","unit_price","discount","total","date","created_by")

class ExpenseSerializer(serializers.ModelSerializer):
    created_by = UserSerializer(read_only=True)
    class Meta:
        model = Expense
        fields = ("id","title","amount","category","date","created_by")
EOF

cat > backend/api/permissions.py <<'EOF'
from rest_framework import permissions

def user_role(user):
    try:
        return user.profile.role
    except:
        return None

class IsAdmin(permissions.BasePermission):
    def has_permission(self, request, view):
        return user_role(request.user) == "admin"

class IsOperatorOrAdmin(permissions.BasePermission):
    def has_permission(self, request, view):
        role = user_role(request.user)
        return role in ("operator", "admin")

class IsAccountantOrAdmin(permissions.BasePermission):
    def has_permission(self, request, view):
        role = user_role(request.user)
        return role in ("accountant", "admin")
EOF

cat > backend/api/views.py <<'EOF'
from rest_framework import viewsets, status
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.contrib.auth.models import User
from .models import Invoice, Expense
from .serializers import InvoiceSerializer, ExpenseSerializer, UserSerializer
from .permissions import IsAdmin, IsOperatorOrAdmin, IsAccountantOrAdmin

class InvoiceViewSet(viewsets.ModelViewSet):
    queryset = Invoice.objects.all().order_by("-date")
    serializer_class = InvoiceSerializer

    def get_permissions(self):
        if self.action in ("create", "update", "partial_update", "destroy"):
            return [IsAuthenticated(), IsOperatorOrAdmin()]
        return [IsAuthenticated()]

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)

    def get_queryset(self):
        user = self.request.user
        role = getattr(getattr(user, "profile", None), "role", None)
        if role in ("operator", "admin", "accountant"):
            return super().get_queryset()
        return Invoice.objects.none()

    @action(detail=True, methods=["get"])
    def export_pdf(self, request, pk=None):
        return Response({"detail": "PDF generation placeholder"}, status=status.HTTP_200_OK)

class ExpenseViewSet(viewsets.ModelViewSet):
    queryset = Expense.objects.all().order_by("-date")
    serializer_class = ExpenseSerializer

    def get_permissions(self):
        if self.action in ("list", "retrieve", "create", "update", "partial_update", "destroy"):
            return [IsAuthenticated(), IsAccountantOrAdmin()]
        return [IsAuthenticated()]

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)

class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all().order_by("username")
    serializer_class = UserSerializer

    def get_permissions(self):
        if self.action in ("create", "update", "partial_update", "destroy"):
            return [IsAuthenticated(), IsAdmin()]
        return [IsAuthenticated()]

@api_view(["GET"])
@permission_classes([IsAuthenticated])
def me(request):
    user = request.user
    serializer = UserSerializer(user)
    return Response(serializer.data)
EOF

cat > backend/api/urls.py <<'EOF'
from rest_framework import routers
from django.urls import path, include
from .views import InvoiceViewSet, ExpenseViewSet, UserViewSet, me

router = routers.DefaultRouter()
router.register(r"invoices", InvoiceViewSet)
router.register(r"expenses", ExpenseViewSet)
router.register(r"users", UserViewSet)

urlpatterns = [
    path("", include(router.urls)),
    path("me/", me, name="me"),
]
EOF

cat > backend/README.md <<'EOF'
# Backend (Django + DRF)

نصب و راه‌اندازی سریع:

1. virtualenv بساز و فعال کن:
   python -m venv venv
   source venv/bin/activate  (Linux/macOS) یا venv\\Scripts\\activate (Windows)

2. نصب پکیج‌ها:
   pip install -r requirements.txt

3. migrate و ساخت سوپر‌یوزر:
   python manage.py makemigrations
   python manage.py migrate
   python manage.py createsuperuser

4. اجرا:
   python manage.py runserver 0.0.0.0:8000

توجه: برای توسعه می‌توان از sqlite استفاده کرد؛ برای production از PostgreSQL و تنظیمات محیطی استفاده کن.
EOF

cat > backend/.env.example <<'EOF'
DJANGO_SECRET_KEY=change-me
DJANGO_DEBUG=1
DB_ENGINE=django.db.backends.sqlite3
DB_NAME=db.sqlite3
ACCESS_TOKEN_MINUTES=60
EOF

# ---------------- frontend files ----------------
cat > frontend/package.json <<'EOF'
{
  "name": "kabel-asia-frontend",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev -p 3000",
    "build": "next build",
    "start": "next start"
  },
  "dependencies": {
    "axios": "^1.4.0",
    "lucide-react": "^0.270.0",
    "next": "13.4.10",
    "react": "18.2.0",
    "react-dom": "18.2.0"
  }
}
EOF

cat > frontend/next.config.js <<'EOF'
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
};
module.exports = nextConfig;
EOF

cat > frontend/.env.local.example <<'EOF'
NEXT_PUBLIC_API_URL=http://localhost:8000/api
EOF

cat > frontend/lib/api.js <<'EOF'
import axios from "axios";

const API_BASE = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000/api";

const instance = axios.create({
  baseURL: API_BASE,
  headers: {
    "Content-Type": "application/json"
  }
});

export function setToken(token) {
  if (token) instance.defaults.headers.common["Authorization"] = `Bearer ${token}`;
  else delete instance.defaults.headers.common["Authorization"];
}

export default instance;
EOF

cat > frontend/pages/_app.js <<'EOF'
import "../styles/globals.css";
import { useEffect } from "react";
import { setToken } from "../lib/api";

function MyApp({ Component, pageProps }) {
  useEffect(() => {
    const token = localStorage.getItem("accessToken");
    if (token) setToken(token);
  }, []);
  return <Component {...pageProps} />;
}

export default MyApp;
EOF

cat > frontend/pages/index.js <<'EOF'
import { useState, useEffect } from "react";
import api, { setToken } from "../lib/api";
import Login from "../components/Login";
import Layout from "../components/Layout";
import InvoiceModal from "../components/InvoiceModal";

export default function Home() {
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const [currentUser, setCurrentUser] = useState(null);
  const [invoices, setInvoices] = useState([]);
  const [showInvoiceModal, setShowInvoiceModal] = useState(false);
  const [editingInvoice, setEditingInvoice] = useState(null);

  useEffect(() => {
    const t = localStorage.getItem("accessToken");
    if (t) {
      setToken(t);
      fetchMe();
      setIsLoggedIn(true);
    }
  }, []);

  const fetchMe = async () => {
    try {
      const res = await api.get("/me/");
      setCurrentUser({
        username: res.data.username,
        name: res.data.first_name || res.data.username,
        role: res.data.profile?.role || "operator"
      });
      loadInvoices();
    } catch (err) {
      console.error(err);
    }
  };

  const loadInvoices = async () => {
    try {
      const res = await api.get("/invoices/");
      setInvoices(res.data);
    } catch (err) {
      console.error(err);
    }
  };

  const handleLogin = async ({ username, password }) => {
    try {
      const res = await api.post("/token/", { username, password });
      const access = res.data.access;
      localStorage.setItem("accessToken", access);
      setToken(access);
      setIsLoggedIn(true);
      await fetchMe();
    } catch (err) {
      alert("نام کاربری یا رمز اشتباه است");
    }
  };

  const openNewInvoice = (inv = null) => {
    setEditingInvoice(inv);
    setShowInvoiceModal(true);
  };

  const handleSaveInvoice = async (payload) => {
    try {
      if (editingInvoice && editingInvoice.id) {
        await api.put(`/invoices/${editingInvoice.id}/`, {
          customer: payload.customer,
          type: payload.type,
          area: payload.area,
          unit_price: payload.unit_price,
          discount: payload.discount
        });
      } else {
        await api.post("/invoices/", {
          customer: payload.customer,
          type: payload.type,
          area: payload.area,
          unit_price: payload.unit_price,
          discount: payload.discount
        });
      }
      setShowInvoiceModal(false);
      await loadInvoices();
    } catch (err) {
      console.error(err);
      alert("خطا هنگام ذخیره فاکتور");
    }
  };

  if (!isLoggedIn) return <Login onLogin={handleLogin} />;

  return (
    <Layout currentUser={currentUser} onLogout={() => { localStorage.removeItem("accessToken"); setToken(null); setIsLoggedIn(false); }}>
      <div className="p-6">
        <div className="flex gap-4 mb-6">
          <button onClick={() => openNewInvoice()} className="py-3 px-6 bg-amber-500 rounded-xl text-white font-bold">فاکتور جدید</button>
        </div>

        <div className="grid gap-4">
          {invoices.map(inv => (
            <div key={inv.id} className="p-4 bg-slate-800 rounded-xl flex justify-between items-center cursor-pointer" onClick={() => openNewInvoice(inv)}>
              <div>
                <div className="font-bold">{inv.customer}</div>
                <div className="text-xs text-slate-400">{inv.type} — {inv.date}</div>
              </div>
              <div className="text-amber-400 font-black">{inv.total?.toLocaleString?.() || inv.total} AFN</div>
            </div>
          ))}
        </div>
      </div>

      {showInvoiceModal && <InvoiceModal invoice={editingInvoice} onClose={() => setShowInvoiceModal(false)} onSave={handleSaveInvoice} />}
    </Layout>
  );
}
EOF

cat > frontend/components/Login.jsx <<'EOF'
import { useState } from "react";

export default function Login({ onLogin }) {
  const [u,setU] = useState("");
  const [p,setP] = useState("");
  return (
    <div className="min-h-screen flex items-center justify-center bg-slate-950" dir="rtl">
      <div className="bg-slate-900 p-12 rounded-3xl w-full max-w-md">
        <h2 className="text-2xl font-black text-amber-400 mb-6">ورود</h2>
        <input value={u} onChange={e=>setU(e.target.value)} className="w-full p-4 rounded-xl mb-4 bg-slate-800 text-white" placeholder="نام کاربری" />
        <input value={p} onChange={e=>setP(e.target.value)} type="password" className="w-full p-4 rounded-xl mb-4 bg-slate-800 text-white" placeholder="رمز عبور" />
        <button onClick={()=>onLogin({ username:u, password:p })} className="w-full p-4 bg-amber-500 rounded-xl font-bold">ورود</button>
      </div>
    </div>
  );
}
EOF

cat > frontend/components/Layout.jsx <<'EOF'
export default function Layout({ children, currentUser, onLogout }) {
  return (
    <div className="min-h-screen bg-slate-950 text-white" dir="rtl">
      <aside className="w-72 fixed h-full p-8 bg-slate-900">
        <h3 className="text-amber-400 font-black mb-6">کابل آسیا</h3>
        <div className="mt-auto">
          <div className="mb-4">
            <div className="font-bold">{currentUser?.name || currentUser?.username}</div>
            <div className="text-xs text-slate-400">{currentUser?.role}</div>
          </div>
          <button onClick={onLogout} className="w-full bg-rose-500 p-3 rounded-xl">خروج</button>
        </div>
      </aside>
      <main className="lg:mr-72 p-6">
        {children}
      </main>
    </div>
  );
}
EOF

cat > frontend/components/InvoiceModal.jsx <<'EOF'
import { useState, useMemo } from "react";

export default function InvoiceModal({ invoice, onClose, onSave }) {
  const [form, setForm] = useState({
    customer: invoice?.customer || "",
    type: invoice?.type || "CNC",
    area: invoice?.area || 0,
    unit_price: invoice?.unit_price || invoice?.unitPrice || 0,
    discount: invoice?.discount || 0,
  });

  const total = useMemo(() => (Number(form.area) * Number(form.unit_price)) - (Number(form.discount) || 0), [form]);

  const submit = (e) => {
    e.preventDefault();
    onSave({
      customer: form.customer,
      type: form.type,
      area: Number(form.area),
      unit_price: Number(form.unit_price),
      discount: Number(form.discount),
      total
    });
  };

  return (
    <div className="fixed inset-0 flex items-center justify-center bg-black/70" dir="rtl">
      <div className="bg-slate-900 p-8 rounded-2xl w-full max-w-md">
        <h3 className="text-amber-400 font-black mb-4">{invoice ? "ویرایش فاکتور" : "فاکتور جدید"}</h3>
        <form onSubmit={submit} className="space-y-3">
          <input className="w-full p-3 rounded-xl bg-slate-800 text-white" value={form.customer} onChange={e=>setForm({...form, customer:e.target.value})} placeholder="نام مشتری" />
          <select className="w-full p-3 rounded-xl bg-slate-800 text-white" value={form.type} onChange={e=>setForm({...form, type:e.target.value})}>
            <option value="CNC">CNC</option>
            <option value="PVC">PVC</option>
            <option value="Cutting">Cutting</option>
            <option value="Carpentry">Carpentry</option>
          </select>
          <div className="grid grid-cols-2 gap-2">
            <input className="p-3 rounded-xl bg-slate-800 text-white" type="number" value={form.area} onChange={e=>setForm({...form, area:e.target.value})} placeholder="متراژ" />
            <input className="p-3 rounded-xl bg-slate-800 text-white" type="number" value={form.unit_price} onChange={e=>setForm({...form, unit_price:e.target.value})} placeholder="فی واحد" />
          </div>
          <input className="w-full p-3 rounded-xl bg-slate-800 text-white" type="number" value={form.discount} onChange={e=>setForm({...form, discount:e.target.value})} placeholder="تخفیف" />
          <div className="flex justify-between items-center">
            <div className="font-black text-amber-400">{total.toLocaleString()} AFN</div>
            <div className="flex gap-2">
              <button type="button" onClick={onClose} className="px-4 py-2 rounded-xl bg-slate-700">انصراف</button>
              <button type="submit" className="px-4 py-2 rounded-xl bg-amber-500 text-black font-bold">ذخیره</button>
            </div>
          </div>
        </form>
      </div>
    </div>
  );
}
EOF

cat > frontend/styles/globals.css <<'EOF'
:root{
  --bg:#0f1724;
  --card:#0b1220;
}
html,body,#__next { height:100%; }
body { margin:0; font-family: Inter, ui-sans-serif, system-ui, -apple-system, "Segoe UI", Roboto, "Helvetica Neue", Arial; background:var(--bg); color: #fff; }
.bg-slate-950 { background: #0b1220; }
.bg-slate-900 { background: #0f1724; }
.bg-slate-800 { background: #172033; }
.text-amber-400 { color: #f59e0b; }
.bg-amber-500 { background: #f59e0b; }
.bg-rose-500 { background: #fb7185; }
.rounded-xl { border-radius: 12px; }
.rounded-2xl { border-radius: 16px; }
EOF

cat > frontend/README.md <<'EOF'
# Frontend (Next.js)

نصب و اجرا:

1. نصب پکیج‌ها:
   npm install

2. فایل .env.local بساز و مقدار BACKEND را قرار بده (می‌توانی از .env.local.example استفاده کنی):
   NEXT_PUBLIC_API_URL=http://localhost:8000/api

3. اجرا:
   npm run dev
EOF

echo "تمام فایل‌ها نوشته شدند."

echo "اینیشیالایز گیت..."
git init
git checkout -b "${BRANCH}" || true
git add .
git commit -m "${COMMIT_MSG}"

echo "اضافه کردن remote و push..."
git remote add origin "${REMOTE_URL}" || true

# Try to push. If fails due to non-empty remote, show helpful message.
if git push -u origin "${BRANCH}"; then
  echo "Push موفق بود!"
  echo "Repository URL: ${REMOTE_URL}"
else
  echo "Push با خطا مواجه شد. احتمالاً مخزن از قبل دارای commit است."
  echo "اقدامات پیشنهادی:"
  echo "1) اگر می‌خواهید پوش ابتدا overwrite شود، این دستور را اجرا کنید:"
  echo "   git push -u origin ${BRANCH} --force"
  echo "2) یا ابتدا تغییرات remote را pull کنید و سپس push:"
  echo "   git pull --rebase origin ${BRANCH}"
  echo "سپس مجدداً دستور push را اجرا کن."
  exit 1
fi

echo "تمام شد."
EOF
