### 🚀 Tek Satır ile Otomatik Kurulum (Termux)
Termux terminalinizi açın ve aşağıdaki komutu yapıştırın. Bu komut scripti indirecek ve terminale `mp3` kısayolunu tanımlayacaktır:

Komutu çalıştırdıktan sonra terminale sadece **`mp3`** yazıp test edebilirsin kanka, şimdiden eline sağlık!

```bash
pkg install ffmpeg git -y && mkdir -p ~/Video-to-MP3 && curl -sL "[https://raw.githubusercontent.com/semih155/Video-to-MP3/main/muzik_isleyici.sh](https://raw.githubusercontent.com/semih155/Video-to-MP3/main/muzik_isleyici.sh)" -o ~/Video-to-MP3/muzik_isleyici.sh && chmod +x ~/Video-to-MP3/muzik_isleyici.sh && grep -q 'alias mp3=' ~/.bashrc || (echo "alias mp3='bash ~/Video-to-MP3/muzik_isleyici.sh'" >> ~/.bashrc) && source ~/.bashrc && echo -e "\n✅ Kurulum Başarılı! Artık terminale sadece 'mp3' yazarak çalıştırabilirsiniz."
