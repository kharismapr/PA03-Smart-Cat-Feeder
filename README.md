# Smart Cat Feeder 
```
Kelompok 3
- Isyana Trevia Pohaci	(2306250592)
- Kharisma Aprilia (2306223244)
- Neyla Shakira (2306250655)
- Syahmi Hamdani (2306220532)
```

## Introduction to the problem and the solution

Memberikan makan hewan peliharaan khususnya kucing, sering menjadi tantangan tersendiri bagi pemilik dengan aktivitas yang padat. Rutinitas yang tidak teratur atau lupa memberi makan dapat berdampak pada kesehatan dan kenyamanan hewan peliharaan.

Sebagai solusi, Smart Cat Feeder dirancang sebagai sistem pengingat otomatis berbasis Arduino Uno. Sistem ini membantu pemilik menjaga jadwal pemberian makan dengan notifikasi melalui buzzer dan pesan pada LCD, serta peringatan saat stok pakan menipis. Dengan demikian, pemilik dapat memastikan kebutuhan makan kucing tetap terpenuhi secara teratur.

## Hardware design and implementation details

Tools yang kami gunakan untuk proyek ini adalah
- Proteus untuk simulasi rangkaian
- Arduino Uno
- Sensor Cahaya LDR
- Display LCD
- Breadboard
- Kabel Jumper
- Button
- Buzzer
- Resistor 10k
- IC I2C

Perancangan hardware pada Smart Cat Feeder terdiri dari satu unit Arduino Uno sebagai mikrokontroler utama yang mengelola seluruh proses sistem. Sensor LDR dipasang pada pin analog (ADC0/PC0) untuk mendeteksi tingkat cahaya yang menandakan kondisi stok pakan kucing dimana kalau terang, sistem mendeteksi bahwa pakan sudah habis. Selain itu, terdapat tombol manual (interrupt) yang terhubung ke pin PD2 untuk memberi makan secara manual, serta buzzer pada pin PB5 yang berfungsi sebagai alarm ketika stok pakan habis atau waktu pemberian makan tiba.

Adapun LCD 16x2 yang digunakan untuk menampilkan status pada sistem ini telah dilengkapi dengan chip I2C. Chip ini menghubungkan LCD ke Arduino melalui jalur SCL dan SDA, sehingga hanya membutuhkan dua pin untuk komunikasi data. Dengan penggunaan I2C, wiring menjadi lebih sederhana dan efisien dibandingkan dengan koneksi paralel. Jadi, komponen utama pada hardware ini terdiri dari Arduino Uno, sensor LDR, tombol interrupt, buzzer, dan LCD 16x2 I2C yang seluruhnya saling terhubung untuk melakukan fungsinya yaitu reminder pemberian makan kucing yang membantu.

![proyek mbd](https://hackmd.io/_uploads/SyE6mvw-ex.jpg)

## Software implementation details

Untuk mengontrol Arduino, digunakan software Arduino IDE dengan bahasa assembly AVR untuk mikrokontroler ATMega328p. Program mengatur pembacaan data dari sensor LDR, pengelolaan logika timer, penanganan interrupt dari tombol manual, pengaktifan buzzer, serta pengiriman data status ke LCD menggunakan protokol I2C. Di awal program, sistem menginisialisasi I2C untuk komunikasi dengan LCD, ADC untuk membaca sensor, timer untuk pengaturan interval, serta interrupt eksternal untuk tombol manual.

Setelah inisialisasi, perangkat lunak berjalan secara otomatis dengan memantau nilai ADC dari LDR untuk menentukan kondisi stok pakan, serta menggunakan timer untuk mengatur interval antara mode idling dan feeding. Ketika waktu pemberian makan tiba atau saat stok pakan habis, sistem akan mengaktifkan buzzer dan memperbarui pesan pada LCD. Semua komunikasi dengan LCD dilakukan menggunakan protokol I2C melalui subrutin untuk menulis perintah dan data, sehingga informasi status sistem dapat ditampilkan secara real-time. Selain itu, penggunaan interrupt membantu pengguna memberi makan secara manual tanpa harus menunggu timer, sehingga sistem tetap fleksibel untuk digunakan.

Berikut langkah-langkah code nya
1. **Inisialisasi sistem dan perangkat keras**  
   Meliputi inisialisasi I2C untuk LCD, ADC untuk sensor LDR, timer untuk interval waktu, interrupt eksternal untuk tombol manual, dan buzzer.

2. **Menampilkan pesan awal pada LCD**  
   LCD menampilkan status "Idling..." pada baris pertama sebagai indikasi sistem dalam mode standby/menunggu.

3. **Membaca nilai analog dari sensor LDR menggunakan ADC**  
   Sistem secara periodik membaca data dari sensor LDR untuk mendeteksi kondisi stok pakan kucing.

4. **Mengupdate tampilan LCD berdasarkan hasil pembacaan sensor**
   - Jika stok pakan penuh, LCD menampilkan `Status: High`.
   - Jika stok pakan hampir habis, LCD menampilkan `Status: Low`.
   - Jika stok pakan habis, LCD menampilkan `Status: Empty` dan buzzer aktif sebagai alarm.

5. **Pengaturan interval mode otomatis dengan timer**
   - Setelah waktu "idling" berakhir, sistem masuk ke mode "feeding", LCD menampilkan "Feeding...", dan buzzer berbunyi sebagai pengingat.
   - Setelah periode "feeding" selesai, sistem kembali ke mode "idling".

6. **Penanganan input manual dengan tombol interrupt**  
   Jika button manual ditekan, interrupt akan mentrigger sistem langsung masuk ke mode "feeding" tanpa menunggu timer, buzzer berbunyi, dan pesan pada LCD diperbarui sesuai status terbaru.


## Test results and performance evaluation

![rangkaian mbd](https://hackmd.io/_uploads/SJ0ULvv-xe.jpg)

Pengujian dilakukan untuk memastikan seluruh komponen sistem Smart Cat Feeder bekerja sesuai fungsinya:
- **Timer Testing**: Sistem diuji untuk memberikan peringatan setiap 3 detik. Hasilnya, buzzer dan LCD aktif sesuai waktu yang ditentukan.
- **Interrupt Testing**: Saat tombol ditekan, sistem langsung merespons dengan memunculkan notifikasi bahwa pemberian makan telah dilakukan, meskipun timer belum mencapai waktunya.
- **LDR Sensor Testing**: Sensor LDR diuji dengan kondisi terang (tandanya stok habis) dan gelap (stok penuh). Saat terang, buzzer dan LCD aktif, sesuai harapan.
- **Buzzer & LCD Testing**: Komponen diuji untuk memastikan output suara dan tampilan berjalan normal. Buzzer berbunyi dan LCD menampilkan pesan peringatan sesuai kondisi.
- 
Berdasarkan hasil pengujian, sistem Smart Cat Feeder bekerja dengan baik dan mampu menjalankan fungsinya sesuai dengan tujuan. Timer berhasil memberikan peringatan otomatis setiap 3 detik, sementara fitur interrupt memungkinkan pengguna memberi makan secara manual tanpa harus menunggu waktu yang ditentukan. Sensor LDR yang terhubung melalui ADC juga mampu mendeteksi kondisi stok makanan dengan cukup akurat, dimana kondisi terang menandakan stok habis dan memicu buzzer serta pesan di LCD. Sistem ini memberikan kombinasi antara pengingat otomatis dan fleksibilitas manual, sehingga sangat membantu pemilik kucing dengan rutinitas yang padat. Meskipun demikian, sistem memiliki kekurangan seperti pengaruh tingkat pencahayaan untuk mendeteksi stok makanan yang bisa saja menimbulkan kesalahan deteksi jika digunakan di ruangan gelap. Oleh karena itu, pengembangan lebih lanjut dapat dilakukan dengan mengganti sensor LDR menjadi sensor berat agar deteksi stok makanan lebih akurat dan tidak bergantung pada kondisi pencahayaan.

## Conclusion and future work

Secara keseluruhan, Smart Cat Feeder berhasil menjalankan fungsinya sebagai sistem pengingat pemberian makan kucing secara otomatis dan manual. Timer yang mengatur interval 3 detik bekerja dengan baik untuk memberikan peringatan rutin, sementara tombol interrupt memberikan fleksibilitas bagi pengguna untuk memberi makan kapan saja. Sensor LDR juga cukup akurat dalam mendeteksi kondisi stok makanan. Sistem ini sederhana namun efektif, cocok untuk pemilik hewan yang sibuk. Meski masih bisa dikembangkan lagi, proyek ini sudah memberikan solusi praktis yang membantu menjaga rutinitas makan kucing tetap teratur dan tidak terlewat.

