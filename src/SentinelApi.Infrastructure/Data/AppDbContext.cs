using SentinelApi.Core.Models;
using Microsoft.EntityFrameworkCore;

namespace SentinelApi.Infrastructure.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<User> Users => Set<User>();
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();
    public DbSet<SecureFileMetadata> SecureFiles => Set<SecureFileMetadata>();
    public DbSet<AuditLog> AuditLogs => Set<AuditLog>();
    public DbSet<EmailVerificationToken> EmailVerificationTokens => Set<EmailVerificationToken>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // User Configuration
        modelBuilder.Entity<User>(builder =>
        {
            builder.HasKey(u => u.Id);
            builder.HasIndex(u => new { u.ClientId, u.Username }).IsUnique();
            builder.HasIndex(u => new { u.ClientId, u.Email }).IsUnique();
            builder.Property(u => u.Username).HasMaxLength(50).IsRequired();
            builder.Property(u => u.Email).HasMaxLength(100).IsRequired();
            builder.Property(u => u.Role).HasMaxLength(30).IsRequired();
            builder.Property(u => u.ClientId).HasMaxLength(50).IsRequired();
        });

        // RefreshToken Configuration
        modelBuilder.Entity<RefreshToken>(builder =>
        {
            builder.HasKey(rt => rt.Id);
            builder.HasIndex(rt => rt.Token).IsUnique();
            builder.HasIndex(rt => rt.UserId);
        });

        // SecureFileMetadata Configuration
        modelBuilder.Entity<SecureFileMetadata>(builder =>
        {
            builder.HasKey(sf => sf.Id);
            builder.HasIndex(sf => sf.UploadedByUserId);
        });

        // AuditLog Configuration
        modelBuilder.Entity<AuditLog>(builder =>
        {
            builder.HasKey(al => al.Id);
            builder.HasIndex(al => al.Timestamp);
            builder.HasIndex(al => al.RiskLevel);
            builder.HasIndex(al => al.UserId);
        });

        // EmailVerificationToken Configuration
        modelBuilder.Entity<EmailVerificationToken>(builder =>
        {
            builder.HasKey(ev => ev.Id);
            builder.HasIndex(ev => ev.UserId);
            builder.Property(ev => ev.OtpHash).HasMaxLength(128).IsRequired();
        });
    }
}
