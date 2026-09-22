# Limpa TODOS os dados de produção e recria apenas o administrador do CESEP.
#
# Rodado pelo workflow .github/workflows/reset-db.yml, que envia este arquivo
# pela stdin do container que já está no ar:
#
#   docker exec -i -e RESET_CONFIRM='APAGAR TUDO' <container> bin/rails runner - < script/reset_production.rb
#
# Por isso não precisa de redeploy: o script não vive dentro da imagem.
#
# TRUNCATE em vez de db:drop/db:create porque o Postgres é um acessório do Kamal
# no mesmo servidor: derrubar o banco exigiria parar o app (o Solid Queue roda
# dentro do Puma e segura conexões) e recriar os 4 bancos. O TRUNCATE preserva
# schema_migrations e não toca nos bancos _cache/_queue/_cable.

abort("ABORTADO: só roda em production (ambiente atual: #{Rails.env})") unless Rails.env.production?
abort("ABORTADO: RESET_CONFIRM não confere") unless ENV["RESET_CONFIRM"] == "APAGAR TUDO"

# As credenciais NÃO ficam no repositório: vêm dos secrets ADMIN_EMAIL e
# ADMIN_PASSWORD do GitHub (Settings -> Secrets and variables -> Actions),
# repassados pelo workflow. O Actions mascara secrets nos logs do job.
ADMIN_EMAIL    = ENV["ADMIN_EMAIL"].to_s.strip
ADMIN_PASSWORD = ENV["ADMIN_PASSWORD"].to_s

abort("ABORTADO: ADMIN_EMAIL vazio (secret não configurado?)") if ADMIN_EMAIL.empty?
abort("ABORTADO: ADMIN_PASSWORD vazio (secret não configurado?)") if ADMIN_PASSWORD.empty?

# Checado ANTES do backup e do TRUNCATE: uma senha fora do padrão faria o
# User.save! estourar já com o banco zerado e sem admin.
unless ADMIN_PASSWORD.match?(User::PASSWORD_REGEX)
  abort("ABORTADO: ADMIN_PASSWORD não atende a regra (8-100 chars, 1 minúscula, 1 maiúscula, 1 dígito)")
end

# A ordem não importa para o TRUNCATE (é uma só instrução, com CASCADE), mas as
# dependentes vêm primeiro para facilitar a leitura. schema_migrations e
# ar_internal_metadata ficam DE FORA de propósito.
TABLES = %w[
  active_storage_attachments
  active_storage_variant_records
  active_storage_blobs
  anamneses
  medical_records
  payments
  services
  service_recurrences
  rooms
  users
  profiles
].freeze

puts "[1/4] Backup do banco para o S3 (ponto de restauração)..."
DatabaseBackupJob.perform_now

# purge apaga o arquivo no S3 junto com o registro. Feito pelo ORM (e não só no
# TRUNCATE) para não deixar objetos órfãos pagando storage no bucket.
# Atenção: o S3 não participa da transação abaixo. Se o passo 4 falhar e o banco
# voltar, os registros de blob reaparecem apontando para arquivos já apagados —
# basta rodar de novo, que a limpeza recomeça do zero.
puts "[2/4] Purgando anexos e arquivos do S3..."
ActiveStorage::Attachment.find_each(&:purge)
ActiveStorage::Blob.find_each(&:purge)

# Limpeza e criação do admin na MESMA transação: no Postgres o TRUNCATE é
# transacional, então qualquer erro ao criar o admin (e-mail inválido no secret,
# validação nova no model) desfaz o TRUNCATE junto e o banco volta ao que era.
# Sem isso, uma falha no passo 4 deixaria produção zerada e sem ninguém para logar.
profile = nil
user = nil

ActiveRecord::Base.transaction do
  puts "[3/4] Limpando as tabelas de domínio..."
  quoted = TABLES.map { |table| ActiveRecord::Base.connection.quote_table_name(table) }.join(", ")
  ActiveRecord::Base.connection.execute("TRUNCATE TABLE #{quoted} RESTART IDENTITY CASCADE")

  puts "[4/4] Criando o administrador..."
  profile = Profile.create!(
    name: "Administrador CESEP",
    email: ADMIN_EMAIL,
    gender: :other,
    birth: Date.new(2007, 11, 1),
    role: :therapist,
    admin: true
  )

  # confirmable está ligado: sem skip_confirmation! o login é barrado até alguém
  # clicar no link do e-mail.
  user = User.new(
    email: ADMIN_EMAIL,
    password: ADMIN_PASSWORD,
    password_confirmation: ADMIN_PASSWORD,
    profile: profile
  )
  user.skip_confirmation!
  user.save!
end

puts ""
puts "profiles=#{Profile.count} users=#{User.count} services=#{Service.count} " \
     "payments=#{Payment.count} anamneses=#{Anamnese.count} " \
     "medical_records=#{MedicalRecord.count} rooms=#{Room.count} " \
     "blobs=#{ActiveStorage::Blob.count}"
puts "admin: #{user.email} admin?=#{profile.admin?} ativo?=#{profile.active?} confirmado?=#{user.confirmed?}"
puts "OK"
