# Catálogo Home Brew

Um app nativo de macOS, em SwiftUI, que funciona como uma enciclopédia gráfica para o
[Homebrew](https://brew.sh): navega o catálogo completo de formulae e casks, organizado por
funcionalidade, com descrições traduzidas para português, e permite instalar, atualizar e
desinstalar pacotes direto pela interface — sem precisar abrir o Terminal.

## Funcionalidades

- **Catálogo completo offline**: baixa e cacheia localmente todo o catálogo do Homebrew
  (~16 mil formulae + casks) via [SwiftData](https://developer.apple.com/documentation/swiftdata).
- **Navegação por facetas**: Tudo / Formulae / Casks, Instalados, Atualizações disponíveis,
  Descontinuados, Taps de origem, e por **funcionalidade** (Desenvolvimento, Bancos de Dados,
  Redes, Segurança, Multimídia, Jogos, Fontes, Produtividade, Sistema, Ciência e Dados...).
- **Descrições traduzidas** para português automaticamente, on-device, via o framework
  [Translation](https://developer.apple.com/documentation/translation) da Apple (sem custo, sem
  internet depois de baixado o pacote de idioma).
- **Busca inteligente**: acha pacotes tanto pelo nome/descrição literal quanto pela função em
  português — buscar "visualizador de pdf" encontra os leitores de PDF do catálogo, mesmo com
  a descrição original em inglês.
- **Indicador de preço/licença**: mostra a licença open-source real das formulae, e uma
  estimativa de Grátis/Pago/Freemium para casks a partir da descrição.
- **Instalar, atualizar e desinstalar** pacotes com um clique, com log de saída do `brew` ao
  vivo, sem precisar do Terminal.

## Requisitos

- macOS 15 (Sequoia) ou mais recente.
- [Homebrew](https://brew.sh) instalado (`/opt/homebrew` ou `/usr/local`).

## Instalação

No momento não há um binário pré-compilado disponível — veja [Build a partir do
código-fonte](#build-a-partir-do-código-fonte) abaixo.

## Build a partir do código-fonte

### Pré-requisitos

- [Xcode](https://developer.apple.com/xcode/) 16 ou mais recente.
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — o projeto Xcode é gerado a partir do
  `project.yml`, não é versionado diretamente:

  ```bash
  brew install xcodegen
  ```

### Compilando

```bash
git clone https://github.com/<seu-usuario>/catalogo-home-brew.git
cd catalogo-home-brew
xcodegen generate
open "Catálogo Home Brew.xcodeproj"
```

Ou, para compilar direto pelo terminal (modo Release) e instalar em `/Applications`:

```bash
xcodegen generate
xcodebuild -project BrewCatalog.xcodeproj -scheme BrewCatalog -configuration Release build
cp -R "$(xcodebuild -project BrewCatalog.xcodeproj -scheme BrewCatalog -configuration Release -showBuildSettings | awk -F ' = ' '/ TARGET_BUILD_DIR /{print $2; exit}')/Catálogo Home Brew.app" /Applications/
```

> O app precisa rodar **sem App Sandbox** para conseguir chamar o `brew` do sistema — por isso
> não é (e não pode ser) distribuído pela Mac App Store.

## Arquitetura

- **SwiftUI + SwiftData** — interface declarativa e persistência local do catálogo.
- **XcodeGen** — o `project.yml` é a fonte da verdade; o `.xcodeproj` é gerado e ignorado pelo
  git.
- **Framework `Translation` da Apple** — duas sessões on-device: uma EN→PT (traduz descrições
  sob demanda, ao abrir um pacote) e outra PT→EN (traduz o termo de busca pra cruzar com as
  descrições originais em inglês).
- **`Process`/`Pipe`** — executa o `brew` real do sistema (`install`/`uninstall`/`upgrade`) e
  transmite a saída ao vivo pra um painel de log dentro do app.
- Categorização por funcionalidade e indicador de preço são heurísticas por palavras-chave
  (o Homebrew não expõe esses dados nativamente) — não são 100% precisas.

## Limitações conhecidas

- A categorização por funcionalidade e o indicador de preço são estimativas — o Homebrew não
  fornece esses dados, então usamos regras por palavras-chave na descrição original em inglês.
- Formulae sempre aparecem como "Grátis" (são sempre open-source, por política do próprio
  Homebrew); casks sem sinal claro de preço na descrição aparecem como "Não informado".
- Um aviso do AppKit ("reentrant operation in NSTableView delegate") pode aparecer no console
  ocasionalmente durante a carga inicial do catálogo — não afeta o funcionamento, mas a Apple
  sinaliza que pode virar um erro fatal em versões futuras do macOS.

## Licença

Distribuído sob a licença MIT — veja [LICENSE](LICENSE).
