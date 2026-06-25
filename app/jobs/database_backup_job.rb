require "open3"
require "zlib"

# Faz o backup do banco de dados (pg_dump), comprime em .gz e envia para o Amazon S3.
# Roda automaticamente todo dia via Solid Queue (ver config/recurring.yml).
# Os backups ficam no MESMO bucket dos uploads, sob o prefixo "backups/".
# A retenção (apagar backups antigos) é feita por uma regra de Lifecycle do S3 (ver o plano, Parte 4).
class DatabaseBackupJob < ApplicationJob
  queue_as :default

  def perform
    bucket = ENV["AWS_S3_BUCKET"].to_s
    if bucket.empty?
      Rails.logger.error("[db-backup] AWS_S3_BUCKET não definido — backup abortado")
      return
    end

    db = ActiveRecord::Base.connection_db_config.configuration_hash
    timestamp = Time.now.utc.strftime("%Y%m%d-%H%M%S")
    key = "backups/#{db[:database]}/#{timestamp}.sql.gz"

    raw = Rails.root.join("tmp", "db-backup-#{timestamp}.sql")
    gz  = Rails.root.join("tmp", "db-backup-#{timestamp}.sql.gz")

    dump_database(db, raw)
    compress(raw, gz)
    upload(bucket, key, gz)

    Rails.logger.info("[db-backup] backup enviado: s3://#{bucket}/#{key} (#{File.size(gz)} bytes)")
  ensure
    File.delete(raw) if raw && File.exist?(raw)
    File.delete(gz)  if gz  && File.exist?(gz)
  end

  private

  # Gera o dump SQL com pg_dump gravando direto num arquivo (sem pipe, evita travamento).
  # A senha vai pela variável PGPASSWORD; a saída de erro segue para os logs do container.
  def dump_database(db, raw_path)
    env = { "PGPASSWORD" => db[:password].to_s }
    args = [
      "pg_dump",
      "--host=#{db[:host]}",
      "--port=#{db[:port] || 5432}",
      "--username=#{db[:username]}",
      "--no-owner",
      "--no-privileges",
      db[:database].to_s
    ]

    ok = system(env, *args, out: raw_path.to_s)
    raise "[db-backup] pg_dump falhou (veja os logs acima)" unless ok
  end

  # Comprime o .sql em .sql.gz usando a Zlib (sem depender do binário gzip).
  def compress(raw_path, gz_path)
    Zlib::GzipWriter.open(gz_path) do |gz|
      File.open(raw_path, "rb") do |file|
        while (chunk = file.read(64 * 1024))
          gz.write(chunk)
        end
      end
    end
  end

  # Envia o arquivo comprimido para o S3, usando as mesmas credenciais do Active Storage (via ENV).
  def upload(bucket, key, gz_path)
    require "aws-sdk-s3"
    client = Aws::S3::Client.new(
      region: ENV.fetch("AWS_REGION", "sa-east-1"),
      access_key_id: ENV["AWS_ACCESS_KEY_ID"],
      secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"]
    )
    File.open(gz_path, "rb") do |file|
      client.put_object(bucket: bucket, key: key, body: file)
    end
  end
end
