# ML Kit (mobile_scanner) bileşenlerini Firebase ComponentDiscovery yansımayla (reflection) oluşturur:
# Class.getDeclaredConstructor().newInstance(). R8 tam modda yalnızca sınıf adını tutan kural yapıcıyı
# korumaz; yapıcı silinince release derlemede tarayıcı "null object reference" ile açılmaz.
-keepclassmembers class * implements com.google.firebase.components.ComponentRegistrar {
    public <init>();
}
