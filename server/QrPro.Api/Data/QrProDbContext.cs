using Microsoft.EntityFrameworkCore;

namespace QrPro.Api.Data;

public sealed class QrProDbContext(DbContextOptions<QrProDbContext> options) : DbContext(options)
{
    public DbSet<Purchase> Purchases => Set<Purchase>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Purchase>(e =>
        {
            e.ToTable("purchases");
            e.HasKey(p => p.Id);
            e.Property(p => p.Id).HasColumnName("id").UseIdentityAlwaysColumn();
            e.Property(p => p.Token).HasColumnName("token").IsRequired();
            e.Property(p => p.PackageName).HasColumnName("package_name").IsRequired();
            e.Property(p => p.ProductId).HasColumnName("product_id").IsRequired();
            e.Property(p => p.OrderId).HasColumnName("order_id");
            e.Property(p => p.Status).HasColumnName("status").IsRequired();
            e.Property(p => p.Reason).HasColumnName("reason");
            e.Property(p => p.RawResponse).HasColumnName("raw_response").HasColumnType("jsonb");
            e.Property(p => p.RequestCount).HasColumnName("request_count").HasDefaultValue(1);
            e.Property(p => p.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");
            e.Property(p => p.UpdatedAt).HasColumnName("updated_at").HasDefaultValueSql("now()");

            e.HasIndex(p => p.Token).IsUnique().HasDatabaseName("ux_purchases_token");
            // Silme talebinde sipariş numarasıyla arama.
            e.HasIndex(p => p.OrderId).HasDatabaseName("ix_purchases_order_id");
        });
    }
}
