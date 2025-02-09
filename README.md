# 🚖 Uber Clone

## 📌 Sobre o Projeto
Este projeto é um aplicativo inspirado na Uber, desenvolvido para conectar motoristas e passageiros. Com ele, usuários podem solicitar viagens, acompanhar corridas em tempo real e gerenciar suas contas. A aplicação utiliza Firebase para autenticação, armazenamento de dados e comunicação entre os usuários.

---

## Índice
1. [Visão Geral](#-visão-geral)
2. [Principais Funcionalidades](#-principais-funcionalidades)
3. [Tecnologias Utilizadas](#-tecnologias-utilizadas)
4. [Capturas de Tela](#-capturas-de-tela)
   - [Autenticação](#-autênticação)
   - [Menu do Passageiro](#-menu-do-passageiro)
   - [Menu do Motorista](#-menu-do-motorista)
   - [Telas de Viagem](#-telas-de-viagem)
   - [Ver Detalhes Corrida](#-ver-detalhes-corrida)
5. [Estrutura do Projeto](#-estrutura-do-projeto)
6. [Como Rodar o Projeto](#-como-rodar-o-projeto)
7. [Faça uma Contribuição](#-contribuição)
8. [Licença](#-licença)
9. [Autores](#-autores)
10. [Links Úteis](#-links-úteis)

---

## 🔍 Visão Geral
Este aplicativo replica funcionalidades essenciais da Uber, proporcionando uma experiência de corrida segura e eficiente. Passageiros podem solicitar viagens, enquanto motoristas recebem solicitações e navegam até o destino. O Firebase é utilizado para garantir uma integração ágil e confiável entre usuários.

---

## 🔥 Principais Funcionalidades
- 📍 **Solicitação de Corridas**: Passageiros podem solicitar corridas e motoristas podem aceitá-las.
- 📜 **Histórico de Corridas**: Visualização de todas as corridas realizadas com filtros de busca funcionais.
- 🧑‍💼 **Gerenciamento de Conta**: Alteração de foto de perfil, nome, email e senha.
- 🔐 **Autenticação Segura**: Login e cadastro via Firebase Authentication.
- ☁️ **Banco de Dados em Tempo Real**: Armazena e sincroniza os dados dos usuários via Firebase Firestore.

---

## 🛠 Tecnologias Utilizadas
- **Flutter** (Dart)
- **Firebase Authentication**
- **Firebase Firestore**
- **Google Maps API**

---

## 📸 Capturas de Tela
### 📱 Autênticação
<div style="display: flex; gap: 10px;">
  <img src="https://github.com/user-attachments/assets/a52f811b-0a33-4d33-83f4-787058347da5" style="width: 32%;"/>
  <img src="https://github.com/user-attachments/assets/f0227edc-ecbe-4d07-8177-f9c40fce8c01" style="width: 32%;"/>
  <img src="https://github.com/user-attachments/assets/ec94867e-8449-436d-8aa0-b59636124c94" style="width: 32%;"/>
</div>

### 🚖 Menu do Passageiro
<div style="display: flex; gap: 10px;">
  <img src="https://github.com/user-attachments/assets/412a46e4-00c0-4234-ad26-5813a15d05a7" style="width: 24%;"/>
  <img src="https://github.com/user-attachments/assets/4d6a37d5-b20d-4835-8cb7-ab49016d71ae" style="width: 24%;"/>
  <img src="https://github.com/user-attachments/assets/85024dc0-3dbb-4f8f-b490-24624907dc31" style="width: 24%;"/>
  <img src="https://github.com/user-attachments/assets/6120c09a-26e0-4ef4-9c45-7e457a4ec533" style="width: 24%;"/>
</div>

### 🚗 Menu do Motorista
<div style="display: flex; gap: 10px;">
  <img src="https://github.com/user-attachments/assets/715315c1-2d2a-4fd3-9249-859a4b0dcd63" style="width: 24%;"/>
  <img src="https://github.com/user-attachments/assets/f9294328-98c6-49e3-8c82-500f40ebac51" style="width: 24%;"/>
  <img src="https://github.com/user-attachments/assets/880b46c6-eebf-4522-bace-95e5a6bb2a90" style="width: 24%;"/>
  <img src="https://github.com/user-attachments/assets/8fe9c736-7de1-4145-8dd3-40506e819952" style="width: 24%;"/>
</div>

### 🧳 Telas de Viagem
<div style="display: flex; gap: 10px;">
  <img src="https://github.com/user-attachments/assets/45468dd5-e1b1-4566-b9b8-04320468ae4d" style="width: 24%;"/>
  <img src="https://github.com/user-attachments/assets/d87d8f70-ecf8-44c6-9633-5e720eba6f74" style="width: 24%;"/>
  <img src="https://github.com/user-attachments/assets/7b1f4e7a-5b81-4250-abb5-ea1598d47828" style="width: 24%;"/>
  <img src="https://github.com/user-attachments/assets/1a5d7196-7598-4a7a-af9a-9e63b5acc389" style="width: 24%;"/>
</div>

### 💻 Ver detalhes Corrida
<div style="display: flex; gap: 10px;">
  <img src="https://github.com/user-attachments/assets/5bdd7594-5333-42a3-bab5-817cbc2f4749" style="width: 32%;"/>
  <img src="https://github.com/user-attachments/assets/95465fe4-b044-4cf5-a442-dd65e07e69c7" style="width: 32%;"/>
  <img src="https://github.com/user-attachments/assets/f50e1e1a-e875-4fdf-ab8c-cccb62f80a87" style="width: 32%;"/>
</div>

### ⚙️ Configurações
<div style="display: flex; gap: 10px;">
  <img src="https://github.com/user-attachments/assets/374989e7-05db-41bb-a5ae-bef122882681" style="width: 32%;"/>
  <img src="https://github.com/user-attachments/assets/3370531c-71a7-4d5d-bfcf-5364f71e0ff7" style="width: 32%;"/>
  <img src="https://github.com/user-attachments/assets/3e45cc4d-7276-491c-8d6f-9309d43cdd90" style="width: 32%;"/>
</div>

---

## 📂 Estrutura do Projeto
```
/uber_clone
│── lib/
│   ├── src/
│   │   ├── components/                    # Componentes reutilizáveis
│   │   │   ├── custom_alert_dialog.dart
│   │   │   ├── custom_button.dart
│   │   │   ├── custom_input_text.dart
│   │   │   ├── custom_overlay.dart
│   │   │   ├── custom_show_dialog.dart
│   │   │   ├── custom_snackbar.dart
│   │   │   ├── custom_text_area.dart
│   │   ├── models/                        # Modelos de dados
│   │   │   ├── destino.dart
│   │   │   ├── marcador.dart
│   │   │   ├── requisicao.dart
│   │   │   ├── usuario.dart
│   │   ├── pages/                         # Telas do aplicativo
│   │   │   ├── auth/                      # Telas de autenticação
│   │   │   │   ├── cadastro_page.dart
│   │   │   │   ├── login_page.dart
│   │   │   │   ├── redefinir_senha_page.dart
│   │   │   ├── configuracoes/             # Telas da parte de configurações do aplicativo
│   │   │   │   ├── gerenciamento/         # Telas das tabbars de gerenciamento
│   │   │   │   │   ├── ajuda_page.dart
│   │   │   │   │   ├── carteira_page.dart
│   │   │   │   │   ├── configuracoes_page.dart
│   │   │   │   ├── menu_pages/            # Telas do menu principal
│   │   │   │   │   ├── atividade_page.dart
│   │   │   │   │   ├── conta_page.dart
│   │   │   │   │   ├── detalhe_corrida_page.dart
│   │   │   │   │   ├── home_page.dart
│   │   │   │   │   ├── initial_page.dart
│   │   │   │   ├── corrida_page.dart
│   │   │   │   ├── painel_motorista.dart
│   │   │   │   ├── painel_passageiro.dart
│   │   │   │   ├── splash_screen_page.dart
│   │   ├── routes/                       # Gerenciamento das rotas
│   │   │   ├── routes.dart
│   │   ├── utils/                        # Modelos uteis
│   │   │   ├── colors.dart
│   │   │   ├── status_requisicao.dart
│   │   │   ├── usuario_firebase.dart
│   │── main.dart

```

# 🚀 Como Rodar o Projeto
1. Clone este repositório:
   ```sh
   git clone https://github.com/kaiqueGeraldo/uber.git
   ```
2. Acesse a pasta do projeto:
   ```sh
   cd uber-clone
   ```
3. Instale as dependências:
   ```sh
   flutter pub get
   ```
4. Configure o Firebase:
   - Acesse o [Firebase Console](https://console.firebase.google.com/).
   - Crie um novo projeto ou selecione um existente.
   - Adicione um aplicativo Android.
   - Baixe o arquivo `google-services.json` para Android e mova para `android/app/`.
   - No terminal, execute:
     ```sh
     flutterfire configure
     ```
     para integrar automaticamente os serviços do Firebase.
5. Configure a API do Google Maps:
   - Acesse o [Google Cloud Console](https://console.cloud.google.com/).
   - Crie um novo projeto ou selecione um existente.
   - Ative a API do Google Maps.
   - Gere uma chave de API e adicione-a ao arquivo `AndroidManifest.xml` (Android).
6. Execute o aplicativo:
   ```sh
   flutter run
   ```

---

## 📌 Contribuição
Contribuições são bem-vindas! Para contribuir:
1. Faça um fork do projeto.
2. Crie uma branch com sua feature: `git checkout -b minha-feature`.
3. Commit suas mudanças: `git commit -m 'Adicionando nova feature'`.
4. Faça um push da branch: `git push origin minha-feature`.
5. Abra um Pull Request.

---

## 📄 Licença
Este projeto está sob a licença MIT. Veja o arquivo `LICENSE` para mais detalhes.

---

## 🧑🏽 Autores
- **Kaique Geraldo** - [LinkedIn](https://www.linkedin.com/in/kaique-geraldo) | [GitHub](https://github.com/kaiqueGeraldo) | [Email](mailto:kaiique2404@gmail.com)

---

## 🔗 Links Úteis
- [Documentação do Flutter](https://flutter.dev/docs)
- [Documentação do Firebase](https://firebase.google.com/docs?hl=pt-br)

---

💡 **Dúvidas ou sugestões?** Entre em contato ou abra uma issue! 🚀
