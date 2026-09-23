# 05 — Roles and Permissions

| Capability | User | Volunteer | Admin |
|---|---:|---:|---:|
| Register | Yes | No/self-registration | No |
| Login | Yes | Yes | Yes |
| Symptom checker | Yes | No | No |
| Nearby hospitals/camps | Yes | Optional/read-only | Yes |
| Raise SOS | Yes | No | No |
| View own emergency | Yes | Yes for assigned | Yes |
| Accept emergency | No | Yes if assigned | No |
| Resolve emergency | No | Yes if assigned | Admin override if required |
| Set Active/Offline | No | Yes | Admin can monitor/control suspension |
| Complete volunteer profile | No | Yes | Can view/edit where authorized |
| Upload volunteer documents | No | Yes | View/review |
| Verify volunteer | No | No | Yes |
| Create volunteer account | No | No | Yes |
| Create camp | No | No | Yes |
| Manage camps | No | No | Yes |
| View all volunteers | No | No | Yes |
| View all alerts | No | No | Yes |
| View assignment history | Own | Own assigned | All |
| Change app language | Yes | No requirement in V1 | No requirement in V1 |

Server-side authorization is mandatory.
