1. Используем команду $ git show -s aefea чтобы получить полный хэш коммита и сообщение без вывода различий:
commit aefead2207ef7e2aa5dc81a34aedf0cad4c32545
Update CHANGELOG.md

2. Используем команду $ git show -s 85024d3 чтобы получить тег коммита:
v0.12.23

3. С помощью команды $ git show --pretty=format:'%P' b8d720 узнаём, что родителей у этого коммита два: 56cd7859e05c36c06b56d013b55a252d0bb7e158 и 9ea88f22fc6269854151c571162c5bcf958bee2b
Также это наглядно видно, если выполним команду $ git log b8d720 --pretty=oneline --graph -10

4. Командой $ git log v0.12.23..v0.12.24 --pretty=oneline можем узать хэши и комментарии коммитов, которые были сделаны между тегами v0.12.23 и v0.12.24:
b14b74c4939dcab573326f4e3ee2a62e23e12f89 [Website] vmc provider links
3f235065b9347a758efadc92295b540ee0a5e26e Update CHANGELOG.md
6ae64e247b332925b872447e9ce869657281c2bf registry: Fix panic when server is unreachable
5c619ca1baf2e21a155fcdb4c264cc9e24a2a353 website: Remove links to the getting started guide's old location
06275647e2b53d97d4f0a19a0fec11f6d69820b5 Update CHANGELOG.md
d5f9411f5108260320064349b757f55c09bc4b80 command: Fix bug when using terraform login on Windows
4b6d06cc5dcb78af637bbb19c198faff37a066ed Update CHANGELOG.md
dd01a35078f040ca984cdd349f18d0b67e486c35 Update CHANGELOG.md
225466bc3e5f35baa5d07197bbc079345b77525e Cleanup after v0.12.23 release

5. С помощью команды $ git log -S'func providerSource' --oneline выясняем, что данная фунция упоминалась только в двух коммитах:
5af1e6234 main: Honor explicit provider_installation CLI config when present
8c928e835 main: Consult local directories as potential mirrors of providers
Посмотрим на самый ранний коммит $ git show 8c928e835 и увидим следующее:
+func providerSource(services *disco.Disco) getproviders.Source {
то есть была добавлена строчка, которая объявляет данную функцию

6. Командой $ git grep 'func globalPluginDirs' находим файл, в котором упоминается данная функция - это файл plugins.go.
Затем с помощью команды $ git log -s -L :globalPluginDirs:plugins.go --oneline находим все изменения функции в этом файле:
78b122055 Remove config.go and update things using its aliases
52dbf9483 keep .terraform.d/plugins for discovery
41ab0aef7 Add missing OS_ARCH dir to global plugin paths
66ebff90c move some more plugin search path logic to command
8364383c3 Push plugin discovery down into command package

7. Командой $ git log -p --pretty=short -S'func synchronizedWriters' узнаем, что есть два коммита, в которых упоминается данная функция, но лишь в раннем коммите эта функция первый раз объявляется. Коммит и автор:
commit 5ac311e2a91e381e2f52234668b49ba670aa0fe5
Author: Martin Atkins <mart@degeneration.co.uk>
