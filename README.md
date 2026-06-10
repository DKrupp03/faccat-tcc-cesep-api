# Back-end (API) — Sistema de Gestão de Clínica

API REST do sistema de gestão para o Centro de Serviços em Psicologia da FACCAT (CESEP) desenvolvido como **Trabalho de Conclusão de Curso (TCC)**. A API concentra as regras de negócio e os dados do sistema: **prontuário eletrônico**, **controle financeiro**, **agendamento de atendimentos** e gestão de pacientes e terapeutas.

Este repositório contém apenas o back-end. Ele é consumido pelo [front-end em React](https://github.com/DKrupp03/faccat-tcc-cesep-front) (repositório git independente).

## Tecnologias

- **Ruby on Rails 8.1** (modo API)
- **PostgreSQL** — banco de dados
- **Devise + Devise-JWT** — autenticação por token JWT (com revogação por JTI)
- **Active Storage** — armazenamento de anexos (fotos, comprovantes, documentos)
- **Rack::Attack** — rate limiting e proteção contra força bruta (login, signup, recuperação de senha)
- **Rack::CORS** — controle de origens (allowlist do front-end)
- **Kaminari** — paginação
- **Solid Cache / Solid Queue / Solid Cable** — cache, filas e websockets sobre o banco
- **Puma** — servidor web
- **Docker / Docker Compose** — ambiente de desenvolvimento
- **Kamal** — deploy em container
- **Ferramentas de qualidade/segurança** — RuboCop (Omakase), Brakeman, bundler-audit
- **letter_opener_web** — visualização de e-mails em desenvolvimento

## Principais funcionalidades

- **Autenticação JWT** — login, logout, cadastro, confirmação de conta e recuperação/redefinição de senha, com revogação de token.
- **Controle de acesso por perfil** — autorização baseada no papel do usuário (administrador, terapeuta, paciente).
- **Pacientes e terapeutas** — cadastro e gestão de perfis, com vínculo entre terapeuta e seus pacientes e foto.
- **Anamnese** — anamnese vinculada ao paciente.
- **Prontuário eletrônico** — registros de prontuário por atendimento, com título, data, observações e anexos de documentos.
- **Agendamento de atendimentos** — sessões/atendimentos agendados entre terapeuta e paciente.
- **Controle financeiro** — pagamentos por atendimento (valor, vencimento, método, comprovantes) com status (pago, em aberto, vencido) e dados para gráficos.
- **Filtros, ordenação e paginação** — busca por nome, papel, status de pagamento, datas, etc.

---

> Projeto de TCC. Para o tratamento de dados sensíveis e LGPD, consulte o [SECURITY.md](../SECURITY.md) na raiz do projeto.
