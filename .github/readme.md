# Auto CounterStrikeSharp Update System

## 🎯 Tổng quan

Hệ thống tự động monitor và update CounterStrikeSharp với 3 cấp độ automation:

### 🤖 **Level 1: Full Auto** (Recommended)
- ✅ Tự động check CS# updates 2 lần/ngày
- ✅ Tự động tạo PR khi có version mới
- ✅ Tự động test build trước khi merge
- ✅ Auto-merge nếu build pass
- ✅ Auto-cleanup old branches

### 🔧 **Level 2: Dependabot** 
- ✅ Weekly dependency scanning
- ✅ Auto-create PRs cho NuGet updates
- ✅ Manual review trước khi merge

### 💻 **Level 3: Manual Script**
- ✅ PowerShell script để update thủ công
- ✅ Version comparison và build testing
- ✅ Backup/restore khi có lỗi

## 🚀 Setup Instructions

### 📁 Files cần tạo:

```
.github/
├── workflows/
│   ├── dotnet-auto.yml              # Main build workflow (đã có)
│   └── cs-monitor.yml               # CS# Monitor workflow (MỚI)
├── dependabot.yml                   # Enhanced dependabot (CẬP NHẬT)
└── scripts/
    └── update-cs.ps1                # Manual update script (MỚI)
```

### Step 1: Tạo CS# Monitor Workflow

Tạo file `.github/workflows/cs-monitor.yml`:
```yaml
# Copy nội dung từ artifact "CounterStrikeSharp Monitor Workflow"
```

### Step 2: Cập nhật Dependabot Config  

Cập nhật file `.github/dependabot.yml`:
```yaml
# Copy nội dung từ artifact "Dependabot Configuration" (đã enhanced)
```

### Step 3: Tạo Manual Update Script

Tạo file `scripts/update-cs.ps1`:
```powershell
# Copy nội dung từ artifact "CounterStrikeSharp Update Script"
```

### Step 4: Cập nhật Main Workflow

Workflow chính đã được cập nhật để auto-merge CS# PRs an toàn.

## ⚙️ Configuration

### Customize Monitor Frequency

Trong `cs-monitor.yml`, thay đổi schedule:
```yaml
schedule:
  # Hiện tại: 6 AM và 6 PM UTC
  - cron: '0 6,18 * * *'  
  
  # 3 lần/ngày: 6 AM, 2 PM, 10 PM UTC  
  - cron: '0 6,14,22 * * *'
  
  # Chỉ 1 lần/ngày: 8 AM UTC
  - cron: '0 8 * * *'
```

### Customize Auto-merge Rules

Trong workflow, bạn có thể điều chỉnh:
```yaml
# Auto-merge tất cả CS# updates
if echo "$LATEST_VERSION" | grep -qE "^[0-9]+\.[0-9]+\.[0-9]+"; then
  gh pr merge $PR_NUMBER --auto --squash

# Hoặc chỉ auto-merge patch updates (x.x.PATCH)
if echo "$LATEST_VERSION $CURRENT_VERSION" | awk '{split($1,a,"."); split($2,b,"."); if(a[1]==b[1] && a[2]==b[2] && a[3]>b[3]) exit 0; exit 1}'; then
  gh pr merge $PR_NUMBER --auto --squash
```

## 🛠️ Usage Examples

### Auto Mode (Set và quên)
```bash
# Sau khi setup, hệ thống tự động:
# 1. Check CS# updates 2 lần/ngày
# 2. Tạo PR khi có update  
# 3. Test build
# 4. Auto-merge nếu OK
# 5. Trigger release workflow
```

### Manual Check
```bash
# Trigger manual check
gh workflow run "CS# Version Monitor" -f force_check=true
```

### Manual Script Usage
```powershell
# Check for updates only
.\scripts\update-cs.ps1 -CheckOnly

# Auto-update to latest
.\scripts\update-cs.ps1 -UpdateToLatest  

# Update to specific version
.\scripts\update-cs.ps1 -TargetVersion "1.0.150"

# Force update (even if same version)
.\scripts\update-cs.ps1 -Force
```

## 📊 Monitoring & Notifications

### GitHub Issues
- ❌ Update failures tạo GitHub issue tự động
- 🏷️ Labeled: `bug`, `counterstrikesharp`, `manual-action-required`

### PR Labels
- 🏷️ `counterstrikesharp`: CS# related updates
- 🏷️ `auto-update`: Automated updates  
- 🏷️ `dependencies`: Dependency updates

### Branch Cleanup
- 🧹 Tự động xóa branches cũ sau 7 ngày
- 🔍 Pattern: `update-cs-*`

## 🔧 Advanced Configuration

### Custom Build Commands

Trong `cs-monitor.yml`, customize build test:
```yaml
- name: Test build
  run: |
    # Standard build
    dotnet build HLTV_VoiceFix.csproj -c Release
    
    # Advanced build với custom parameters
    dotnet build HLTV_VoiceFix.csproj -c Release \
      -p:TreatWarningsAsErrors=true \
      -p:WarningsAsErrors="" \
      -p:WarningsNotAsErrors=""
      
    # Run additional tests
    if [ -f "test-plugin.ps1" ]; then
      pwsh test-plugin.ps1
    fi
```

### Custom Notification

Add Discord/Slack webhook:
```yaml
- name: Notify update
  if: success()
  run: |
    curl -X POST "${{ secrets.DISCORD_WEBHOOK }}" \
      -H "Content-Type: application/json" \
      -d '{
        "content": "🚀 CounterStrikeSharp updated to v${{ needs.check-cs-updates.outputs.latest-version }}!"
      }'
```

### Version Pinning

Để pin một version cụ thể:
```yaml
# Trong dependabot.yml
ignore:
  - dependency-name: "CounterStrikeSharp.API"
    versions: ["> 1.0.150"]  # Không update qua 1.0.150
```

## 🐛 Troubleshooting

### CS# Monitor không chạy
```bash
# Check workflow history
gh run list --workflow="CS# Version Monitor"

# View logs của run gần nhất
gh run view --log

# Manual trigger để test
gh workflow run "CS# Version Monitor" -f force_check=true
```

### Auto-merge không hoạt động
```bash
# Check branch protection rules
# Đảm bảo "Require status checks" không block auto-merge

# Check PR status
gh pr list --label "counterstrikesharp"
gh pr view <PR_NUMBER>
```

### Build fail sau update
```bash
# Xem build logs
gh run list --workflow=".NET Auto Build & Release"
gh run view <RUN_ID> --log

# Manual rollback
git revert <commit_hash>
git push origin main
```

### Script PowerShell lỗi
```powershell
# Check execution policy
Get-ExecutionPolicy
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

# Enable detailed errors
$ErrorActionPreference = "Stop"
.\scripts\update-cs.ps1 -CheckOnly
```

## 📈 Best Practices

### 1. **Testing Strategy**
```yaml
# Trong cs-monitor.yml, thêm comprehensive testing
- name: Extended Testing
  run: |
    # Build test
    dotnet build -c Release
    
    # Runtime test (nếu có)
    dotnet test --no-build
    
    # Static analysis (nếu cần)
    dotnet format --verify-no-changes
```

### 2. **Version Strategy**
- 🟢 **Auto-merge patch updates** (1.0.150 → 1.0.151)
- 🟡 **Review minor updates** (1.0.x → 1.1.x)  
- 🔴 **Manual review major updates** (1.x.x → 2.x.x)

### 3. **Branch Protection**
```bash
# Recommended GitHub branch protection:
# ✅ Require status checks to pass
# ✅ Require branches to be up to date  
# ✅ Require conversation resolution
# ❌ Dismiss stale reviews (để auto-merge hoạt động)
```

### 4. **Monitoring**
- 📧 Watch repository để nhận notifications
- 🔔 Setup GitHub mobile app cho alerts
- 📊 Check Actions tab thường xuyên

## 🎉 Benefits

### ⏰ **Time Saving**
- Không cần manual check CS# updates
- Tự động testing và validation
- Zero-downtime updates

### 🛡️ **Safety**
- Build testing trước khi merge
- Automatic rollback nếu fail
- Changelog tracking

### 📈 **Consistency** 
- Always up-to-date với latest CS#
- Consistent update process
- Audit trail via PRs và commits

---

**🎯 Sau khi setup xong, plugin sẽ tự động update CounterStrikeSharp mỗi khi có phiên bản mới!**