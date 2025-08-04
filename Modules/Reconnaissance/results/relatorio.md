# Relatório de Análise

## Metadados
- **Script**: AutoRecon Script (Versão 1.2.4)
- **Sistema Operacional**: Linux hyprarch 6.15.8-arch1-1 #1 SMP PREEMPT_DYNAMIC Thu, 24 Jul 2025 18:18:11 +0000 x86_64 GNU/Linux
- **Hora de Início**: 2025-08-04 18:27:37
- **Usuário**: root
- **Alvo**: www.google.com
- **IPv4 Resolvido**: 142.250.78.132
- **IPv6 Resolvido**: 2800:3f0:4001:801::2004
- **Tipo de Alvo**: DOMAIN
- **Protocolo**: https
- **Hora de Resolução**: 2025-08-04 18:31:07## Configurações das Ferramentas

### Nmap
- nmap 142.250.78.132 -sT -vv -Pn
- nmap 142.250.78.132 -vv -O -Pn
- nmap 142.250.78.132 -sV -O -vv -Pn
- nmap -6 2800:3f0:4001:801::2004 -sT -vv -Pn
- nmap -6 2800:3f0:4001:801::2004 -vv -O -Pn
- nmap -6 2800:3f0:4001:801::2004 -sV -O -vv -Pn

### FFUF
- ffuf -u https://142.250.78.132/ -H \"Host: FUZZ.www.google.com\" -w /tmp/subdomains.txt -mc 200,301,302 -o results/ffuf_subdomains.csv -of csv
- ffuf -u https://142.250.78.132/FUZZ -w /tmp/common.txt -mc 200,301,302 -o results/ffuf_web.csv -of csv
- ffuf -u https://142.250.78.132/index.FUZZ -w /root/wordlists/SecLists/Discovery/Web-Content/web-extensions.txt -mc 200,301,302 -o results/ffuf_extensions.csv -of csv## Dependências

- **jq**: Instalado (jq-1.8.1 || echo 'Não instalado')
- **nmap**: Instalado (Nmap version 7.97 ( https://nmap.org ) || echo 'Não instalado')
- **ffuf**: Instalado (flag provided but not defined: -version || echo 'Não instalado')
- **dig**: Instalado (Invalid option: --version || echo 'Não instalado')
- **traceroute**: Instalado (Modern traceroute for Linux, version 2.1.6 || echo 'Não instalado')
- **curl**: Instalado (curl 8.15.0 (x86_64-pc-linux-gnu) libcurl/8.15.0 OpenSSL/3.5.1 zlib/1.3.1 brotli/1.1.0 zstd/1.5.7 libidn2/2.3.7 libpsl/0.21.5 libssh2/1.11.1 nghttp2/1.66.0 nghttp3/1.11.0 || echo 'Não instalado')
- **nc**: Instalado (nc: invalid option -- '-' || echo 'Não instalado')
- **xmllint**: Instalado (xmllint: using libxml version 21405-GITv2.14.5 || echo 'Não instalado')## Resultados dos Testes


### Teste: Resolução IPv4
- **Status**: Sucesso
- **Mensagem**: ✓ 142.250.78.132
- **Timestamp**: 2025-08-04 18:31:07
- **Detalhes**:
  - Comando: N/A
  - Arquivo de Resultados: N/A


### Teste: Resolução IPv6
- **Status**: Sucesso
- **Mensagem**: ✓ 2800
- **Timestamp**: 2025-08-04 18:31:08
- **Detalhes**:
  - Comando: N/A
  - Arquivo de Resultados: N/A


### Teste: Ping IPv4
- **Status**: Sucesso
- **Mensagem**: ✓ Sucesso (Perda
- **Timestamp**: 2025-08-04 18:31:08
- **Detalhes**:
  - Comando IPv4: ping -c 4 142.250.78.132
  - Comando IPv6: ping6 -c 4 2800:3f0:4001:801::2004
  - Perda de Pacotes: N/A
  - Latência Média: N/A


### Teste: Ping IPv6
- **Status**: Sucesso
- **Mensagem**: ✓ Sucesso (Perda
- **Timestamp**: 2025-08-04 18:31:08
- **Detalhes**:
  - Comando IPv4: ping -c 4 142.250.78.132
  - Comando IPv6: ping6 -c 4 2800:3f0:4001:801::2004
  - Perda de Pacotes: N/A
  - Latência Média: N/A


### Teste: HTTP (https)
- **Status**: Sucesso
- **Mensagem**: ✓ Servidor ativo
- **Timestamp**: 2025-08-04 18:31:08
- **Detalhes**:
  - Comando: curl -sI https://www.google.com
  - Arquivo de Resultados: http_test.txt


### Teste: Nmap IPv4
- **Status**: Sucesso
- **Mensagem**: ✓ Portas escaneadas (19 linhas)
- **Timestamp**: 2025-08-04 18:31:09
- **Detalhes**:
  - Comando: nmap 142.250.78.132 -sT -vv -Pn nmap 142.250.78.132 -vv -O -Pn nmap 142.250.78.132 -sV -O -vv -Pn
  - Arquivo de Resultados: nmap_ipv4_nmap_TARGET_IP_-sT_-vv_-Pn.xml,nmap_ipv4_nmap_TARGET_IP_-sV_-O_-vv_-Pn.xml,nmap_ipv4_nmap_TARGET_IP_-vv_-O_-Pn.xml,nmap_ipv6_nmap_-6_TARGET_IP_-sT_-vv_-Pn.xml,nmap_ipv6_nmap_-6_TARGET_IP_-sV_-O_-vv_-Pn.xml,nmap_ipv6_nmap_-6_TARGET_IP_-vv_-O_-Pn.xml


### Teste: Nmap IPv4
- **Status**: Sucesso
- **Mensagem**: ✓ Portas escaneadas (43 linhas)
- **Timestamp**: 2025-08-04 18:31:09
- **Detalhes**:
  - Comando: nmap 142.250.78.132 -sT -vv -Pn nmap 142.250.78.132 -vv -O -Pn nmap 142.250.78.132 -sV -O -vv -Pn
  - Arquivo de Resultados: nmap_ipv4_nmap_TARGET_IP_-sT_-vv_-Pn.xml,nmap_ipv4_nmap_TARGET_IP_-sV_-O_-vv_-Pn.xml,nmap_ipv4_nmap_TARGET_IP_-vv_-O_-Pn.xml,nmap_ipv6_nmap_-6_TARGET_IP_-sT_-vv_-Pn.xml,nmap_ipv6_nmap_-6_TARGET_IP_-sV_-O_-vv_-Pn.xml,nmap_ipv6_nmap_-6_TARGET_IP_-vv_-O_-Pn.xml


### Teste: Nmap IPv4
- **Status**: Sucesso
- **Mensagem**: ✓ Portas escaneadas (88 linhas)
- **Timestamp**: 2025-08-04 18:31:09
- **Detalhes**:
  - Comando: nmap 142.250.78.132 -sT -vv -Pn nmap 142.250.78.132 -vv -O -Pn nmap 142.250.78.132 -sV -O -vv -Pn
  - Arquivo de Resultados: nmap_ipv4_nmap_TARGET_IP_-sT_-vv_-Pn.xml,nmap_ipv4_nmap_TARGET_IP_-sV_-O_-vv_-Pn.xml,nmap_ipv4_nmap_TARGET_IP_-vv_-O_-Pn.xml,nmap_ipv6_nmap_-6_TARGET_IP_-sT_-vv_-Pn.xml,nmap_ipv6_nmap_-6_TARGET_IP_-sV_-O_-vv_-Pn.xml,nmap_ipv6_nmap_-6_TARGET_IP_-vv_-O_-Pn.xml


### Teste: Nmap IPv6
- **Status**: Sucesso
- **Mensagem**: ✓ Portas escaneadas (19 linhas)
- **Timestamp**: 2025-08-04 18:31:09
- **Detalhes**:
  - Comando: nmap 142.250.78.132 -sT -vv -Pn nmap 142.250.78.132 -vv -O -Pn nmap 142.250.78.132 -sV -O -vv -Pn
  - Arquivo de Resultados: nmap_ipv4_nmap_TARGET_IP_-sT_-vv_-Pn.xml,nmap_ipv4_nmap_TARGET_IP_-sV_-O_-vv_-Pn.xml,nmap_ipv4_nmap_TARGET_IP_-vv_-O_-Pn.xml,nmap_ipv6_nmap_-6_TARGET_IP_-sT_-vv_-Pn.xml,nmap_ipv6_nmap_-6_TARGET_IP_-sV_-O_-vv_-Pn.xml,nmap_ipv6_nmap_-6_TARGET_IP_-vv_-O_-Pn.xml


### Teste: Nmap IPv6
- **Status**: Sucesso
- **Mensagem**: ✓ Portas escaneadas (39 linhas)
- **Timestamp**: 2025-08-04 18:31:09
- **Detalhes**:
  - Comando: nmap 142.250.78.132 -sT -vv -Pn nmap 142.250.78.132 -vv -O -Pn nmap 142.250.78.132 -sV -O -vv -Pn
  - Arquivo de Resultados: nmap_ipv4_nmap_TARGET_IP_-sT_-vv_-Pn.xml,nmap_ipv4_nmap_TARGET_IP_-sV_-O_-vv_-Pn.xml,nmap_ipv4_nmap_TARGET_IP_-vv_-O_-Pn.xml,nmap_ipv6_nmap_-6_TARGET_IP_-sT_-vv_-Pn.xml,nmap_ipv6_nmap_-6_TARGET_IP_-sV_-O_-vv_-Pn.xml,nmap_ipv6_nmap_-6_TARGET_IP_-vv_-O_-Pn.xml


### Teste: Nmap IPv6
- **Status**: Sucesso
- **Mensagem**: ✓ Portas escaneadas (107 linhas)
- **Timestamp**: 2025-08-04 18:31:10
- **Detalhes**:
  - Comando: nmap 142.250.78.132 -sT -vv -Pn nmap 142.250.78.132 -vv -O -Pn nmap 142.250.78.132 -sV -O -vv -Pn
  - Arquivo de Resultados: nmap_ipv4_nmap_TARGET_IP_-sT_-vv_-Pn.xml,nmap_ipv4_nmap_TARGET_IP_-sV_-O_-vv_-Pn.xml,nmap_ipv4_nmap_TARGET_IP_-vv_-O_-Pn.xml,nmap_ipv6_nmap_-6_TARGET_IP_-sT_-vv_-Pn.xml,nmap_ipv6_nmap_-6_TARGET_IP_-sV_-O_-vv_-Pn.xml,nmap_ipv6_nmap_-6_TARGET_IP_-vv_-O_-Pn.xml


### Teste: FFUF Subdomínios
- **Status**: Falha
- **Mensagem**: ✗ Falha
- **Timestamp**: 2025-08-04 18:31:10
- **Detalhes**:
  - Comando: ffuf -u https://142.250.78.132/ -H \"Host: FUZZ.www.google.com\" -w /tmp/subdomains.txt -mc 200,301,302 -o results/ffuf_subdomains.csv -of csv
  - Arquivo de Resultados: ffuf_subdomains.csv


### Teste: FFUF Web
- **Status**: Sucesso
- **Mensagem**: ✓ Recursos web encontrados (198 linhas)
- **Timestamp**: 2025-08-04 18:31:10
- **Detalhes**:
  - Comando: ffuf -u https://142.250.78.132/FUZZ -w /tmp/common.txt -mc 200,301,302 -o results/ffuf_web.csv -of csv
  - Arquivo de Resultados: ffuf_web.csv


### Teste: FFUF Extensões
- **Status**: Falha
- **Mensagem**: ✗ Falha
- **Timestamp**: 2025-08-04 18:31:10
- **Detalhes**:
  - Comando: ffuf -u https://142.250.78.132/index.FUZZ -w /root/wordlists/SecLists/Discovery/Web-Content/web-extensions.txt -mc 200,301,302 -o results/ffuf_extensions.csv -of csv
  - Arquivo de Resultados: ffuf_extensions.csv



## Arquivos de Resultados

### Arquivo: http_test.txt
```txt
    <!doctype html><html itemscope="" itemtype="http://schema.org/WebPage" lang="pt-BR"><head><meta content="text/html; charset=UTF-8" http-equiv="Content-Type"><meta content="/images/branding/googleg/1x/googleg_standard_color_128dp.png" itemprop="image"><title>Google</title><script nonce="nfgqJEeWRwFq2f-UKRjIJw">(function(){var _g={kEI:'1iWRaMzUCNq95OUPg5vFwQE',kEXPI:'0,202854,2,33,1101236,2396211,613,435,538661,14111,64702,94323,266578,290044,5241681,32768934,4043709,25228681,138268,14108,22919,42251,6757,23879,7033,2106,4599,328,6225,54190,9975,15048,50,8154,3296,4135,30376,28335,10902,43308,353,10731,8149,3122,3,2745,7714,5773,8977,7818,8155,2662,4719,11805,3261,2990,35,3420,5355,2,181,7946,12107,5683,69,3536,5657,12114,9162,711,8758,649,4219,6,3,5746,3,1187,283,3874,1738,1856,1763,1219,1,3459,2,217,3504,463,7,487,764,727,1033,952,627,715,1554,5,9303,5,3018,934,981,731,99,2,2,4,1,321,1189,2892,1021,667,34,5615,5,433,4625,965,3,2,2,2,599,732,3443,1588,2990,2714,691,4561,572,2273,217,1157,123,403,187,4,746,633,31,104,3070,483,339,743,1902,448,266,407,573,1134,2,99,437,811,5,682,128,956,714,4,5,158,1564,18,6,412,3,368,194,1116,923,82,28,2006,14,316,1618,2,9,1,300,355,2042,507,44,575,302,1494,134,754,155,171,225,40,564,294,415,134,23,495,493,2,1474,216,30,43,22,1169,577,2181,290,133,18,36,78,918,3,2144,10,785,1108,588,645,1104,523,89,339,273,785,335,561,3,2,2,2,356,415,59,47,118,1291,164,108,217,160,110,94,16,30,237,126,116,1523,380,53,152,605,62,142,19,352,201,3,595,185,355,3,4,5,356,748,43,175,352,53,490,1500,34,6,219,451,615,35,8,612,441,2,77,26,1268,498,269,60,52,197,78,315,811,58,21,13,13,482,3,2,2,2,1110,8,1072,409,259,494,2,4,7,334,1010,12,145,471,113,481,347,651,1201,1340,20778292,416077,5,2992,4,2701,259,3,1308,3507,3676,2,1562,3,1827,3,612,3,1924,63,40,3265,1,572,150,199,2,2,433,624,515,491,213,141,164,350,8487901',kBL:'teMo',kOPI:89978449};(function(){var a;((a=window.google)==null?0:a.stvsc)?google.kEI=_g.kEI:window.google=_g;}).call(this);})();(function(){google.sn='webhp';google.kHL='pt-BR';})();(function(){
    var g=this||self;function k(){return window.google&&window.google.kOPI||null};var l,m=[];function n(a){for(var b;a&&(!a.getAttribute||!(b=a.getAttribute("eid")));)a=a.parentNode;return b||l}function p(a){for(var b=null;a&&(!a.getAttribute||!(b=a.getAttribute("leid")));)a=a.parentNode;return b}function q(a){/^http:/i.test(a)&&window.location.protocol==="https:"&&(google.ml&&google.ml(Error("a"),!1,{src:a,glmm:1}),a="");return a}
    function r(a,b,d,c,h){var e="";b.search("&ei=")===-1&&(e="&ei="+n(c),b.search("&lei=")===-1&&(c=p(c))&&(e+="&lei="+c));var f=b.search("&cshid=")===-1&&a!=="slh";c="&zx="+Date.now().toString();g._cshid&&f&&(c+="&cshid="+g._cshid);(d=d())&&(c+="&opi="+d);return"/"+(h||"gen_204")+"?atyp=i&ct="+String(a)+"&cad="+(b+e+c)};l=google.kEI;google.getEI=n;google.getLEI=p;google.ml=function(){return null};google.log=function(a,b,d,c,h,e){e=e===void 0?k:e;d||(d=r(a,b,e,c,h));if(d=q(d)){a=new Image;var f=m.length;m[f]=a;a.onerror=a.onload=a.onabort=function(){delete m[f]};a.src=d}};google.logUrl=function(a,b){b=b===void 0?k:b;return r("",a,b)};}).call(this);(function(){google.y={};google.sy={};function e(a,b,c){if(a)var d=a.id;else{do d=Math.random();while(c[d])}c[d]=[a,b]}var f;(f=google).x||(f.x=function(a,b){e(a,b,google.y)});var g;(g=google).sx||(g.sx=function(a,b){e(a,b,google.sy)});google.lm=[];var h;(h=google).plm||(h.plm=function(a){google.lm.push.apply(google.lm,a)});google.lq=[];var k;(k=google).load||(k.load=function(a,b,c){google.lq.push([[a],b,c])});var l;(l=google).loadAll||(l.loadAll=function(a,b){google.lq.push([a,b])});google.bx=!1;var m;(m=google).lx||(m.lx=function(){});var n=[],p;(p=google).fce||(p.fce=function(a,b,c,d){n.push([a,b,c,d])});google.qce=n;google.adl=[];}).call(this);google.f={};(function(){
    document.documentElement.addEventListener("submit",function(b){var a;if(a=b.target){var c=a.getAttribute("data-submitfalse");a=c==="1"||c==="q"&&!a.elements.q.value?!0:!1}else a=!1;a&&(b.preventDefault(),b.stopPropagation())},!0);document.documentElement.addEventListener("click",function(b){var a;a:{for(a=b.target;a&&a!==document.documentElement;a=a.parentElement)if(a.tagName==="A"){a=a.getAttribute("data-nohref")==="1";break a}a=!1}a&&b.preventDefault()},!0);}).call(this);</script><style>#gbar,#guser{font-size:13px;padding-top:1px !important;}#gbar{height:22px}#guser{padding-bottom:7px !important;text-align:right}.gbh,.gbd{border-top:1px solid #c9d7f1;font-size:1px}.gbh{height:0;position:absolute;top:24px;width:100%}@media all{.gb1{height:22px;margin-right:.5em;vertical-align:top}#gbar{float:left}}a.gb1,a.gb4{text-decoration:underline !important}a.gb1,a.gb4{color:#00c !important}.gbi .gb4{color:#dd8e27 !important}.gbf .gb4{color:#900 !important}
    </style><style>body,td,a,p,.h{font-family:sans-serif}body{margin:0;overflow-y:scroll}#gog{padding:3px 8px 0}td{line-height:.8em}.gac_m td{line-height:17px}form{margin-bottom:20px}.h{color:#1967d2}em{font-weight:bold;font-style:normal}.lst{height:25px;width:496px}.gsfi,.lst{font:18px sans-serif}.gsfs{font:17px sans-serif}.ds{display:inline-box;display:inline-block;margin:3px 0 4px;margin-left:4px}input{font-family:inherit}body{background:#fff;color:#1f1f1f}a{color:#681da8;text-decoration:none}a:hover,a:active{text-decoration:underline}.fl a{color:#1967d2}a:visited{color:#681da8}.sblc{padding-top:5px}.sblc a{display:block;margin:2px 0;margin-left:13px;font-size:11px}.lsbb{background:#f8f9fa;border:solid 1px;border-color:#dadce0 #70757a #70757a #dadce0;height:30px}.lsbb{display:block}#WqQANb a{display:inline-block;margin:0 12px}.lsb{background:url(/images/nav_logo229.png) 0 -261px repeat-x;color:#1f1f1f;border:none;cursor:pointer;height:30px;margin:0;outline:0;font:15px sans-serif;vertical-align:top}.lsb:active{background:#dadce0}.lst:focus{outline:none}.Ucigb{width:458px}</style><script nonce="nfgqJEeWRwFq2f-UKRjIJw">(function(){window.google.erd={jsr:1,bv:2263,de:true,dpf:'JH7v27ekw8JQS1m7niuD40v9df7mcJaFhhitUOsuw_Y'};
    var g=this||self;var k,l=(k=g.mei)!=null?k:1,m,p=(m=g.diel)!=null?m:0,q,r=(q=g.sdo)!=null?q:!0,t=0,u,w=google.erd,x=w.jsr;google.ml=function(a,b,d,n,e){e=e===void 0?2:e;b&&(u=a&&a.message);d===void 0&&(d={});d.cad="ple_"+google.ple+".aple_"+google.aple;if(google.dl)return google.dl(a,e,d,!0),null;b=d;if(x<0){window.console&&console.error(a,b);if(x===-2)throw a;b=!1}else b=!a||!a.message||a.message==="Error loading script"||t>=l&&!n?!1:!0;if(!b)return null;t++;d=d||{};b=encodeURIComponent;var c="/gen_204?atyp=i&ei="+b(google.kEI);google.kEXPI&&(c+="&jexpid="+b(google.kEXPI));c+="&srcpg="+b(google.sn)+"&jsr="+b(w.jsr)+
    "&bver="+b(w.bv);w.dpf&&(c+="&dpf="+b(w.dpf));var f=a.lineNumber;f!==void 0&&(c+="&line="+f);var h=a.fileName;h&&(h.indexOf("-extension:/")>0&&(e=3),c+="&script="+b(h),f&&h===window.location.href&&(f=document.documentElement.outerHTML.split("
")[f],c+="&cad="+b(f?f.substring(0,300):"No script found.")));google.ple&&google.ple===1&&(e=2);c+="&jsel="+e;for(var v in d)c+="&",c+=b(v),c+="=",c+=b(d[v]);c=c+"&emsg="+b(a.name+": "+a.message);c=c+"&jsst="+b(a.stack||"N/A");c.length>=12288&&(c=c.substring(0,12288));a=c;n||google.log(0,"",a);return a};window.onerror=function(a,b,d,n,e){u!==a&&(a=e instanceof Error?e:Error(a),d===void 0||"lineNumber"in a||(a.lineNumber=d),b===void 0||"fileName"in a||(a.fileName=b),google.ml(a,!1,void 0,!1,a.name==="SyntaxError"||a.message.substring(0,11)==="SyntaxError"||a.message.indexOf("Script error")!==-1?3:p));u=null;r&&t>=l&&(window.onerror=null)};})();</script></head><body bgcolor="#fff"><script nonce="nfgqJEeWRwFq2f-UKRjIJw">(function(){var src='/images/nav_logo229.png';var iesg=false;document.body.onload = function(){window.n && window.n();if (document.images){new Image().src=src;}
    if (!iesg){document.f&&document.f.q.focus();document.gbqf&&document.gbqf.q.focus();}
    }
    })();</script><div id="mngb"><div id=gbar><nobr><b class=gb1>Pesquisa</b> <a class=gb1 href="https://www.google.com/imghp?hl=pt-BR&tab=wi">Imagens</a> <a class=gb1 href="https://maps.google.com.br/maps?hl=pt-BR&tab=wl">Maps</a> <a class=gb1 href="https://play.google.com/?hl=pt-BR&tab=w8">Play</a> <a class=gb1 href="https://www.youtube.com/?tab=w1">YouTube</a> <a class=gb1 href="https://news.google.com/?tab=wn">Not�cias</a> <a class=gb1 href="https://mail.google.com/mail/?tab=wm">Gmail</a> <a class=gb1 href="https://drive.google.com/?tab=wo">Drive</a> <a class=gb1 style="text-decoration:none" href="https://www.google.com.br/intl/pt-BR/about/products?tab=wh"><u>Mais</u> &raquo;</a></nobr></div><div id=guser width=100%><nobr><span id=gbn class=gbi></span><span id=gbf class=gbf></span><span id=gbe></span><a href="http://www.google.com.br/history/optout?hl=pt-BR" class=gb4>Hist�rico da Web</a> | <a  href="/preferences?hl=pt-BR" class=gb4>Configura��es</a> | <a target=_top id=gb_70 href="https://accounts.google.com/ServiceLogin?hl=pt-BR&passive=true&continue=https://www.google.com/&ec=GAZAAQ" class=gb4>Fazer login</a></nobr></div><div class=gbh style=left:0></div><div class=gbh style=right:0></div></div><center><br clear="all" id="lgpd"><div id="XjhHGf"><img alt="Google" height="92" src="/images/branding/googlelogo/1x/googlelogo_white_background_color_272x92dp.png" style="padding:28px 0 14px" width="272" id="hplogo"><br><br></div><form action="/search" name="f"><table cellpadding="0" cellspacing="0"><tr valign="top"><td width="25%">&nbsp;</td><td align="center" nowrap=""><input name="ie" value="ISO-8859-1" type="hidden"><input value="pt-BR" name="hl" type="hidden"><input name="source" type="hidden" value="hp"><input name="biw" type="hidden"><input name="bih" type="hidden"><div class="ds" style="height:32px;margin:4px 0"><div style="position:relative;zoom:1"><input class="lst Ucigb" style="margin:0;padding:5px 8px 0 6px;vertical-align:top;color:#1f1f1f;padding-right:38px" autocomplete="off" value="" title="Pesquisa Google" maxlength="2048" name="q" size="57"><img src="/textinputassistant/tia.png" style="position:absolute;cursor:pointer;right:5px;top:4px;z-index:300" data-script-url="/textinputassistant/13/pt-BR_tia.js" id="tsuid_1iWRaMzUCNq95OUPg5vFwQE_1" alt="" height="23" width="27"><script nonce="nfgqJEeWRwFq2f-UKRjIJw">(function(){var id='tsuid_1iWRaMzUCNq95OUPg5vFwQE_1';document.getElementById(id).onclick = function(){var s = document.createElement('script');s.src = this.getAttribute('data-script-url');document.body.appendChild(s);};})();</script></div></div><br style="line-height:0"><span class="ds"><span class="lsbb"><input class="lsb" value="Pesquisa Google" name="btnG" type="submit"></span></span><span class="ds"><span class="lsbb"><input class="lsb" id="tsuid_1iWRaMzUCNq95OUPg5vFwQE_2" value="Estou com sorte" name="btnI" type="submit"><script nonce="nfgqJEeWRwFq2f-UKRjIJw">(function(){var id='tsuid_1iWRaMzUCNq95OUPg5vFwQE_2';document.getElementById(id).onclick = function(){if (this.form.q.value){this.checked = 1;if (this.form.iflsig)this.form.iflsig.disabled = false;}
    else top.location='/doodles/';};})();</script><input value="AOw8s4IAAAAAaJEz5gSdAOfrmgIUAi_2duElGL9q51Dz" name="iflsig" type="hidden"></span></span></td><td class="fl sblc" align="left" nowrap="" width="25%"><a href="/advanced_search?hl=pt-BR&amp;authuser=0">Pesquisa avan�ada</a></td></tr></table><input id="gbv" name="gbv" type="hidden" value="1"><script nonce="nfgqJEeWRwFq2f-UKRjIJw">(function(){var a,b="1";if(document&&document.getElementById)if(typeof XMLHttpRequest!="undefined")b="2";else if(typeof ActiveXObject!="undefined"){var c,d,e=["MSXML2.XMLHTTP.6.0","MSXML2.XMLHTTP.3.0","MSXML2.XMLHTTP","Microsoft.XMLHTTP"];for(c=0;d=e[c++];)try{new ActiveXObject(d),b="2"}catch(h){}}a=b;if(a=="2"&&location.search.indexOf("&gbv=2")==-1){var f=google.gbvu,g=document.getElementById("gbv");g&&(g.value=a);f&&window.setTimeout(function(){location.href=f},0)};}).call(this);</script></form><div style="font-size:83%;min-height:3.5em"><br></div><span id="footer"><div style="font-size:10pt"><div style="margin:19px auto;text-align:center" id="WqQANb"><a href="/intl/pt-BR/ads/">Publicidade</a><a href="/services/">Solu��es empresariais</a><a href="/intl/pt-BR/about.html">Sobre o Google</a><a href="https://www.google.com/setprefdomain?prefdom=BR&amp;prev=https://www.google.com.br/&amp;sig=K_wd9UXNUJMizx-1Zdg3086uuV_DE%3D">Google.com.br</a></div></div><p style="font-size:8pt;color:#636363">&copy; 2025 - <a href="/intl/pt-BR/policies/privacy/">Privacidade</a> - <a href="/intl/pt-BR/policies/terms/">Termos</a></p></span></center><script nonce="nfgqJEeWRwFq2f-UKRjIJw">(function(){window.google.cdo={height:757,width:1440};(function(){var a=window.innerWidth,b=window.innerHeight;if(!a||!b){var c=window.document,d=c.compatMode=="CSS1Compat"?c.documentElement:c.body;a=d.clientWidth;b=d.clientHeight}if(a&&b&&(a!=google.cdo.width||b!=google.cdo.height)){var e=google,f=e.log,g="/client_204?&atyp=i&biw="+a+"&bih="+b+"&ei="+google.kEI,h="",k=window.google&&window.google.kOPI||null;k&&(h+="&opi="+k);f.call(e,"","",g+h)};}).call(this);})();(function(){google.xjs={basecomb:'/xjs/_/js/k=xjs.hp.en.ldw5DDbKT_k.es5.O/ck=xjs.hp.Z2yX_lwUHQY.L.X.O/am=CAEAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAABAACAAAAhcAAAAABMIAAAAAAgAAEAAAAAAAAAoAAAABgBAAhAiAACAAAAggQAAAUAkwwA40AAgCACgAoEQA5A6QAAAAAQQAAQQAAACAAoAAAAIAEAwAAAAAjgBAAAAMAACI8DAgAAAAAACIgFAAEAAAAAACAeAQ/d=1/ed=1/dg=0/ujg=1/rs=ACT90oF8gqkokKUpmzJgp98OtsZG3-ZHuw',basecss:'/xjs/_/ss/k=xjs.hp.Z2yX_lwUHQY.L.X.O/am=CAEAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAABAACAAAAhcAAAAAAMIAAAAAAgAAAAAAAAAAAAIAAAABABAAhAiAACAAAAggQAAAUAkwAAAwAAACACgAoEQA5A6QAAAAAQQAAQQAAACAAoAAAAIAEAwAAAAAhgBAAAAAAAAIAAAAAAAAAACIg/rs=ACT90oGZqiLnRljybOq5zS_6_zmasYsGpA',basejs:'/xjs/_/js/k=xjs.hp.en.ldw5DDbKT_k.es5.O/am=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAEAAAAAAAAAgAAAAAgBAAhAiAACAAAAAAAAAAQAAAwA4EAAgAAAAAAAAA4AAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAADgAAAAAMAACI8DAgAAAAAACIgFAAEAAAAAACAeAQ/dg=0/rs=ACT90oF4n57BEa8j5V8bYPkci-0FLNW4Ew',excm:[]};})();(function(){var u='/xjs/_/js/k=xjs.hp.en.ldw5DDbKT_k.es5.O/am=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAEAAAAAAAAAgAAAAAgBAAhAiAACAAAAAAAAAAQAAAwA4EAAgAAAAAAAAA4AAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAADgAAAAAMAACI8DAgAAAAAACIgFAAEAAAAAACAeAQ/d=1/ed=1/dg=3/rs=ACT90oF4n57BEa8j5V8bYPkci-0FLNW4Ew/m=sb_he,d';var st=1;var amd=1000;var mmd=0;var pod=true;var pop=true;var povp=false;var fp='';
    var e=this||self;function f(){var b,a,d;if(a=b=(a=window.google)==null?void 0:(d=a.ia)==null?void 0:d.r.B2Jtyd)a=b.m,a=a===1||a===5||a===6;return a&&b.cbfd!=null&&b.cbvi!=null?b:void 0};function g(){var b=[u];if(!google.dp){for(var a=0;a<b.length;a++){var d=b[a],c=document.createElement("link");c.as="script";c.href=d;c.rel="preload";document.body.appendChild(c)}google.dp=!0}};google.ps===void 0&&(google.ps=[]);function h(){var b=u,a=function(){};google.lx=google.stvsc?a:function(){k(b);google.lx=a};google.bx||google.lx()}function l(b,a){a&&(b.src=a);fp&&google.caft&&google.caft(function(){b.fetchPriority=fp});var d=b.onload;b.onload=function(c){d&&d(c);google.ps=google.ps.filter(function(G){return b!==G})};google.ps.push(b);document.body.appendChild(b)}google.as=l;function k(b){google.timers&&google.timers.load&&google.tick&&google.tick("load","xjsls");var a=document.createElement("script");a.onerror=function(){google.ple=1};a.onload=function(){google.ple=0};google.xjsus=void 0;l(a,b);google.aple=-1;google.dp=!0};function m(b){var a=b.getAttribute("jscontroller");return(a==="UBXHI"||a==="R3fhkb"||a==="TSZEqd")&&b.hasAttribute("data-src")}function n(){for(var b=document.getElementsByTagName("img"),a=0,d=b.length;a<d;a++){var c=b[a];if(c.hasAttribute("data-lzy_")&&Number(c.getAttribute("data-atf"))&1&&!m(c))return!0}return!1}for(var p=document.getElementsByTagName("img"),q=0,r=p.length;q<r;++q){var t=p[q];Number(t.getAttribute("data-atf"))&1&&m(t)&&(t.src=t.getAttribute("data-src"))};var w,x,y,z,A,B,C,D,E,F;function H(){google.xjsu=u;e._F_jsUrl=u;A=function(){h()};w=!1;x=(st===1||st===3)&&!!google.caft&&!n();y=f();z=(st===2||st===3)&&!!y&&!n();B=pod;C=pop;D=povp;E=pop&&document.prerendering||povp&&document.hidden;F=D?"visibilitychange":"prerenderingchange"}function I(){w||x||z||E||(A(),w=!0)}
    setTimeout(function(){google&&google.tick&&google.timers&&google.timers.load&&google.tick("load","xjspls");H();if(x||z||E){if(x){var b=function(){x=!1;I()};google.caft(b);window.setTimeout(b,amd)}z&&(b=function(){z=!1;I()},y.cbvi.push(b),window.setTimeout(b,mmd));if(E){var a=function(){(D?document.hidden:document.prerendering)||(E=!1,I(),document.removeEventListener(F,a))};document.addEventListener(F,a,{passive:!0})}if(B||C||D)w||g()}else A()},0);})();window._ = window._ || {};window._DumpException = _._DumpException = function(e){throw e;};window._s = window._s || {};_s._DumpException = _._DumpException;window._qs = window._qs || {};_qs._DumpException = _._DumpException;(function(){var t=[264,0,2048,0,0,0,0,16384,65536,131072,475664,318767104,4194336,67141632,0,16,168,536872672,541623296,838860800,12167,860620852,739127297,8937476,264832,62193721,32,69275652,134217792,40960,1179648,13312,81799424,0,955285516,128,134217728,67114544,0,126353408,1];window._F_toggles = window._xjs_toggles = t;})();window._F_installCss = window._F_installCss || function(css){};(function(){google.jl={bfl:0,dw:false,eli:false,ine:false,ubm:false,uwp:true,vs:false};})();(function(){var pmc='{"d":{},"sb_he":{"client":"heirloom-hp","dh":true,"ds":"","host":"google.com","jsonp":true,"msgs":{"cibl":"Limpar pesquisa","dym":"Voc\u00ea quis dizer:","lcky":"Estou com sorte","lml":"Saiba mais","psrc":"Esta pesquisa foi removida do seu\u003Ca href=\"/history\"\u003EHist\u00f3rico da web\u003C/a\u003E","psrl":"Remover","sbit":"Pesquisa por imagem","srch":"Pesquisa Google"},"ovr":{},"pq":"","rfs":[],"stok":"LwX9I7y9jAdWMwSX7NLNMtbH-VE"}}';google.pmc=JSON.parse(pmc);})();</script></body></html>
```

### Arquivo: ffuf_extensions.csv
```csv
        * stat /root/wordlists/SecLists/Discovery/Web-Content/web-extensions.txt: no such file or directory

    Fuzz Faster U Fool - v2.1.0-dev

    HTTP OPTIONS:
      -H                  Header `"Name: Value"`, separated by colon. Multiple -H flags are accepted.
      -X                  HTTP method to use
      -b                  Cookie data `"NAME1=VALUE1; NAME2=VALUE2"` for copy as curl functionality.
      -cc                 Client cert for authentication. Client key needs to be defined as well for this to work
      -ck                 Client key for authentication. Client certificate needs to be defined as well for this to work
      -d                  POST data
      -http2              Use HTTP2 protocol (default: false)
      -ignore-body        Do not fetch the response content. (default: false)
      -r                  Follow redirects (default: false)
      -raw                Do not encode URI (default: false)
      -recursion          Scan recursively. Only FUZZ keyword is supported, and URL (-u) has to end in it. (default: false)
      -recursion-depth    Maximum recursion depth. (default: 0)
      -recursion-strategy Recursion strategy: "default" for a redirect based, and "greedy" to recurse on all matches (default: default)
      -replay-proxy       Replay matched requests using this proxy.
      -sni                Target TLS SNI, does not support FUZZ keyword
      -timeout            HTTP request timeout in seconds. (default: 10)
      -u                  Target URL
      -x                  Proxy URL (SOCKS5 or HTTP). For example: http://127.0.0.1:8080 or socks5://127.0.0.1:8080

    GENERAL OPTIONS:
      -V                  Show version information. (default: false)
      -ac                 Automatically calibrate filtering options (default: false)
      -acc                Custom auto-calibration string. Can be used multiple times. Implies -ac
      -ach                Per host autocalibration (default: false)
      -ack                Autocalibration keyword (default: FUZZ)
      -acs                Custom auto-calibration strategies. Can be used multiple times. Implies -ac
      -c                  Colorize output. (default: false)
      -config             Load configuration from a file
      -json               JSON output, printing newline-delimited JSON records (default: false)
      -maxtime            Maximum running time in seconds for entire process. (default: 0)
      -maxtime-job        Maximum running time in seconds per job. (default: 0)
      -noninteractive     Disable the interactive console functionality (default: false)
      -p                  Seconds of `delay` between requests, or a range of random delay. For example "0.1" or "0.1-2.0"
      -rate               Rate of requests per second (default: 0)
      -s                  Do not print additional information (silent mode) (default: false)
      -sa                 Stop on all error cases. Implies -sf and -se. (default: false)
      -scraperfile        Custom scraper file path
      -scrapers           Active scraper groups (default: all)
      -se                 Stop on spurious errors (default: false)
      -search             Search for a FFUFHASH payload from ffuf history
      -sf                 Stop when > 95% of responses return 403 Forbidden (default: false)
      -t                  Number of concurrent threads. (default: 40)
      -v                  Verbose output, printing full URL and redirect location (if any) with the results. (default: false)

    MATCHER OPTIONS:
      -mc                 Match HTTP status codes, or "all" for everything. (default: 200-299,301,302,307,401,403,405,500)
      -ml                 Match amount of lines in response
      -mmode              Matcher set operator. Either of: and, or (default: or)
      -mr                 Match regexp
      -ms                 Match HTTP response size
      -mt                 Match how many milliseconds to the first response byte, either greater or less than. EG: >100 or <100
      -mw                 Match amount of words in response

    FILTER OPTIONS:
      -fc                 Filter HTTP status codes from response. Comma separated list of codes and ranges
      -fl                 Filter by amount of lines in response. Comma separated list of line counts and ranges
      -fmode              Filter set operator. Either of: and, or (default: or)
      -fr                 Filter regexp
      -fs                 Filter HTTP response size. Comma separated list of sizes and ranges
      -ft                 Filter by number of milliseconds to the first response byte, either greater or less than. EG: >100 or <100
      -fw                 Filter by amount of words in response. Comma separated list of word counts and ranges

    INPUT OPTIONS:
      -D                  DirSearch wordlist compatibility mode. Used in conjunction with -e flag. (default: false)
      -e                  Comma separated list of extensions. Extends FUZZ keyword.
      -enc                Encoders for keywords, eg. 'FUZZ:urlencode b64encode'
      -ic                 Ignore wordlist comments (default: false)
      -input-cmd          Command producing the input. --input-num is required when using this input method. Overrides -w.
      -input-num          Number of inputs to test. Used in conjunction with --input-cmd. (default: 100)
      -input-shell        Shell to be used for running command
      -mode               Multi-wordlist operation mode. Available modes: clusterbomb, pitchfork, sniper (default: clusterbomb)
      -request            File containing the raw http request
      -request-proto      Protocol to use along with raw request (default: https)
      -w                  Wordlist file path and (optional) keyword separated by colon. eg. '/path/to/wordlist:KEYWORD'

    OUTPUT OPTIONS:
      -audit-log          Write audit log containing all requests, responses and config
      -debug-log          Write all of the internal logging to the specified file.
      -o                  Write output to file
      -od                 Directory path to store matched results to.
      -of                 Output file format. Available formats: json, ejson, html, md, csv, ecsv (or, 'all' for all formats) (default: json)
      -or                 Don't create the output file if we don't have results (default: false)

    EXAMPLE USAGE:
      Fuzz file paths from wordlist.txt, match all responses but filter out those with content-size 42.
      Colored, verbose output.
        ffuf -w wordlist.txt -u https://example.org/FUZZ -mc all -fs 42 -c -v

      Fuzz Host-header, match HTTP 200 responses.
        ffuf -w hosts.txt -u https://example.org/ -H "Host: FUZZ" -mc 200

      Fuzz POST JSON data. Match all responses not containing text "error".
        ffuf -w entries.txt -u https://example.org/ -X POST -H "Content-Type: application/json" \
          -d '{"name": "FUZZ", "anotherkey": "anothervalue"}' -fr "error"

      Fuzz multiple locations. Match only responses reflecting the value of "VAL" keyword. Colored.
        ffuf -w params.txt:PARAM -w values.txt:VAL -u https://example.org/?PARAM=VAL -mr "VAL" -c

      More information and examples: https://github.com/ffuf/ffuf

    Encountered error(s): 1 errors occured.
        * stat /root/wordlists/SecLists/Discovery/Web-Content/web-extensions.txt: no such file or directory

```

### Arquivo: ffuf_subdomains.csv
```csv
        * Either -w or --input-cmd flag is required

    Fuzz Faster U Fool - v2.1.0-dev

    HTTP OPTIONS:
      -H                  Header `"Name: Value"`, separated by colon. Multiple -H flags are accepted.
      -X                  HTTP method to use
      -b                  Cookie data `"NAME1=VALUE1; NAME2=VALUE2"` for copy as curl functionality.
      -cc                 Client cert for authentication. Client key needs to be defined as well for this to work
      -ck                 Client key for authentication. Client certificate needs to be defined as well for this to work
      -d                  POST data
      -http2              Use HTTP2 protocol (default: false)
      -ignore-body        Do not fetch the response content. (default: false)
      -r                  Follow redirects (default: false)
      -raw                Do not encode URI (default: false)
      -recursion          Scan recursively. Only FUZZ keyword is supported, and URL (-u) has to end in it. (default: false)
      -recursion-depth    Maximum recursion depth. (default: 0)
      -recursion-strategy Recursion strategy: "default" for a redirect based, and "greedy" to recurse on all matches (default: default)
      -replay-proxy       Replay matched requests using this proxy.
      -sni                Target TLS SNI, does not support FUZZ keyword
      -timeout            HTTP request timeout in seconds. (default: 10)
      -u                  Target URL
      -x                  Proxy URL (SOCKS5 or HTTP). For example: http://127.0.0.1:8080 or socks5://127.0.0.1:8080

    GENERAL OPTIONS:
      -V                  Show version information. (default: false)
      -ac                 Automatically calibrate filtering options (default: false)
      -acc                Custom auto-calibration string. Can be used multiple times. Implies -ac
      -ach                Per host autocalibration (default: false)
      -ack                Autocalibration keyword (default: FUZZ)
      -acs                Custom auto-calibration strategies. Can be used multiple times. Implies -ac
      -c                  Colorize output. (default: false)
      -config             Load configuration from a file
      -json               JSON output, printing newline-delimited JSON records (default: false)
      -maxtime            Maximum running time in seconds for entire process. (default: 0)
      -maxtime-job        Maximum running time in seconds per job. (default: 0)
      -noninteractive     Disable the interactive console functionality (default: false)
      -p                  Seconds of `delay` between requests, or a range of random delay. For example "0.1" or "0.1-2.0"
      -rate               Rate of requests per second (default: 0)
      -s                  Do not print additional information (silent mode) (default: false)
      -sa                 Stop on all error cases. Implies -sf and -se. (default: false)
      -scraperfile        Custom scraper file path
      -scrapers           Active scraper groups (default: all)
      -se                 Stop on spurious errors (default: false)
      -search             Search for a FFUFHASH payload from ffuf history
      -sf                 Stop when > 95% of responses return 403 Forbidden (default: false)
      -t                  Number of concurrent threads. (default: 40)
      -v                  Verbose output, printing full URL and redirect location (if any) with the results. (default: false)

    MATCHER OPTIONS:
      -mc                 Match HTTP status codes, or "all" for everything. (default: 200-299,301,302,307,401,403,405,500)
      -ml                 Match amount of lines in response
      -mmode              Matcher set operator. Either of: and, or (default: or)
      -mr                 Match regexp
      -ms                 Match HTTP response size
      -mt                 Match how many milliseconds to the first response byte, either greater or less than. EG: >100 or <100
      -mw                 Match amount of words in response

    FILTER OPTIONS:
      -fc                 Filter HTTP status codes from response. Comma separated list of codes and ranges
      -fl                 Filter by amount of lines in response. Comma separated list of line counts and ranges
      -fmode              Filter set operator. Either of: and, or (default: or)
      -fr                 Filter regexp
      -fs                 Filter HTTP response size. Comma separated list of sizes and ranges
      -ft                 Filter by number of milliseconds to the first response byte, either greater or less than. EG: >100 or <100
      -fw                 Filter by amount of words in response. Comma separated list of word counts and ranges

    INPUT OPTIONS:
      -D                  DirSearch wordlist compatibility mode. Used in conjunction with -e flag. (default: false)
      -e                  Comma separated list of extensions. Extends FUZZ keyword.
      -enc                Encoders for keywords, eg. 'FUZZ:urlencode b64encode'
      -ic                 Ignore wordlist comments (default: false)
      -input-cmd          Command producing the input. --input-num is required when using this input method. Overrides -w.
      -input-num          Number of inputs to test. Used in conjunction with --input-cmd. (default: 100)
      -input-shell        Shell to be used for running command
      -mode               Multi-wordlist operation mode. Available modes: clusterbomb, pitchfork, sniper (default: clusterbomb)
      -request            File containing the raw http request
      -request-proto      Protocol to use along with raw request (default: https)
      -w                  Wordlist file path and (optional) keyword separated by colon. eg. '/path/to/wordlist:KEYWORD'

    OUTPUT OPTIONS:
      -audit-log          Write audit log containing all requests, responses and config
      -debug-log          Write all of the internal logging to the specified file.
      -o                  Write output to file
      -od                 Directory path to store matched results to.
      -of                 Output file format. Available formats: json, ejson, html, md, csv, ecsv (or, 'all' for all formats) (default: json)
      -or                 Don't create the output file if we don't have results (default: false)

    EXAMPLE USAGE:
      Fuzz file paths from wordlist.txt, match all responses but filter out those with content-size 42.
      Colored, verbose output.
        ffuf -w wordlist.txt -u https://example.org/FUZZ -mc all -fs 42 -c -v

      Fuzz Host-header, match HTTP 200 responses.
        ffuf -w hosts.txt -u https://example.org/ -H "Host: FUZZ" -mc 200

      Fuzz POST JSON data. Match all responses not containing text "error".
        ffuf -w entries.txt -u https://example.org/ -X POST -H "Content-Type: application/json" \
          -d '{"name": "FUZZ", "anotherkey": "anothervalue"}' -fr "error"

      Fuzz multiple locations. Match only responses reflecting the value of "VAL" keyword. Colored.
        ffuf -w params.txt:PARAM -w values.txt:VAL -u https://example.org/?PARAM=VAL -mr "VAL" -c

      More information and examples: https://github.com/ffuf/ffuf

    Encountered error(s): 1 errors occured.
        * Either -w or --input-cmd flag is required

```

### Arquivo: ffuf_web.csv
```csv
            /'___\  /'___\           /'___\
           /\ \__/ /\ \__/  __  __  /\ \__/
           \ \ ,__\ \ ,__\/\ \/\ \ \ \ ,__\
            \ \ \_/ \ \ \_/\ \ \_\ \ \ \ \_/
             \ \_\   \ \_\  \ \____/  \ \_\
              \/_/    \/_/   \/___/    \/_/

           v2.1.0-dev
    ________________________________________________

     :: Method           : GET
     :: URL              : https://142.250.78.132/FUZZ
     :: Wordlist         : FUZZ: /tmp/common.txt
     :: Output file      : results/ffuf_web.csv
     :: File format      : csv
     :: Follow redirects : false
     :: Calibration      : false
     :: Timeout          : 10
     :: Threads          : 40
     :: Matcher          : Response status: 200,301,302
    ________________________________________________

.well-known/assetlinks.json [Status: 200, Size: 11235, Words: 934, Lines: 269, Duration: 17ms]
.well-known/security.txt [Status: 200, Size: 275, Words: 8, Lines: 8, Duration: 68ms]
accessibility           [Status: 301, Size: 234, Words: 9, Lines: 7, Duration: 11ms]
action                  [Status: 301, Size: 225, Words: 9, Lines: 7, Duration: 66ms]
ads                     [Status: 301, Size: 224, Words: 9, Lines: 7, Duration: 10ms]
advanced_search         [Status: 301, Size: 234, Words: 9, Lines: 7, Duration: 63ms]
adview                  [Status: 301, Size: 225, Words: 9, Lines: 7, Duration: 61ms]
af                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 62ms]
africa                  [Status: 302, Size: 232, Words: 9, Lines: 7, Duration: 61ms]
answers                 [Status: 301, Size: 232, Words: 9, Lines: 7, Duration: 9ms]
apis                    [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 9ms]
apple-app-site-association [Status: 200, Size: 44284, Words: 16179, Lines: 1228, Duration: 9ms]
appliance               [Status: 302, Size: 241, Words: 9, Lines: 7, Duration: 59ms]
ar                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 61ms]
as                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 62ms]
accounts                [Status: 302, Size: 237, Words: 14, Lines: 11, Duration: 714ms]
az                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 65ms]
ban                     [Status: 301, Size: 222, Words: 9, Lines: 7, Duration: 61ms]
be                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 67ms]
bg                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 63ms]
blogger                 [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 14ms]
alerts                  [Status: 200, Size: 152819, Words: 3924, Lines: 270, Duration: 790ms]
br                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 60ms]
books                   [Status: 302, Size: 226, Words: 9, Lines: 7, Duration: 131ms]
bs                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 68ms]
ca                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 62ms]
cars                    [Status: 301, Size: 225, Words: 9, Lines: 7, Duration: 9ms]
calendar                [Status: 302, Size: 0, Words: 1, Lines: 1, Duration: 137ms]
chrome                  [Status: 301, Size: 227, Words: 9, Lines: 7, Duration: 59ms]
bookmarks               [Status: 302, Size: 261, Words: 9, Lines: 7, Duration: 718ms]
co                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 64ms]
commerce                [Status: 301, Size: 229, Words: 9, Lines: 7, Duration: 11ms]
compare                 [Status: 301, Size: 228, Words: 9, Lines: 7, Duration: 12ms]
contact                 [Status: 301, Size: 228, Words: 9, Lines: 7, Duration: 10ms]
crs                     [Status: 301, Size: 222, Words: 9, Lines: 7, Duration: 62ms]
crossdomain.xml         [Status: 200, Size: 235, Words: 9, Lines: 6, Duration: 64ms]
cs                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 60ms]
cy                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 62ms]
da                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 61ms]
de                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 63ms]
ee                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 61ms]
el                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 62ms]
en                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 64ms]
es                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 62ms]
device                  [Status: 302, Size: 243, Words: 14, Lines: 11, Duration: 721ms]
et                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 66ms]
eu                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 99ms]
favicon.ico             [Status: 200, Size: 5430, Words: 10, Lines: 7, Duration: 9ms]
fa                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 70ms]
firefox                 [Status: 301, Size: 226, Words: 9, Lines: 7, Duration: 65ms]
fr                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 62ms]
friends                 [Status: 302, Size: 220, Words: 9, Lines: 7, Duration: 66ms]
ga                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 64ms]
gl                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 67ms]
grants                  [Status: 301, Size: 227, Words: 9, Lines: 7, Duration: 9ms]
health                  [Status: 301, Size: 244, Words: 9, Lines: 7, Duration: 10ms]
health/live             [Status: 301, Size: 244, Words: 9, Lines: 7, Duration: 11ms]
health/ready            [Status: 301, Size: 244, Words: 9, Lines: 7, Duration: 10ms]
home                    [Status: 301, Size: 225, Words: 9, Lines: 7, Duration: 9ms]
hi                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 66ms]
fi                      [Status: 302, Size: 0, Words: 1, Lines: 1, Duration: 867ms]
hosted                  [Status: 301, Size: 227, Words: 9, Lines: 7, Duration: 12ms]
ht                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 65ms]
hr                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 66ms]
ie                      [Status: 301, Size: 244, Words: 9, Lines: 7, Duration: 12ms]
humans.txt              [Status: 200, Size: 286, Words: 48, Lines: 2, Duration: 61ms]
hu                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 72ms]
ig                      [Status: 301, Size: 225, Words: 9, Lines: 7, Duration: 9ms]
ia                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 66ms]
id                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 63ms]
images                  [Status: 301, Size: 225, Words: 9, Lines: 7, Duration: 61ms]
index.html              [Status: 301, Size: 229, Words: 9, Lines: 7, Duration: 61ms]
is                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 60ms]
it                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 64ms]
iw                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 66ms]
ja                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 67ms]
ko                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 73ms]
la                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 62ms]
lg                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 69ms]
lo                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 64ms]
logos                   [Status: 301, Size: 235, Words: 9, Lines: 7, Duration: 10ms]
lv                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 64ms]
lt                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 66ms]
mail                    [Status: 301, Size: 230, Words: 9, Lines: 7, Duration: 10ms]
m                       [Status: 301, Size: 220, Words: 9, Lines: 7, Duration: 63ms]
local                   [Status: 301, Size: 224, Words: 9, Lines: 7, Duration: 313ms]
manifest                [Status: 301, Size: 227, Words: 9, Lines: 7, Duration: 62ms]
mini                    [Status: 302, Size: 232, Words: 9, Lines: 7, Duration: 64ms]
mobile                  [Status: 301, Size: 227, Words: 9, Lines: 7, Duration: 9ms]
mk                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 63ms]
maps                    [Status: 301, Size: 223, Words: 9, Lines: 7, Duration: 320ms]
ml                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 71ms]
mo                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 66ms]
movies                  [Status: 301, Size: 233, Words: 9, Lines: 7, Duration: 10ms]
ms                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 61ms]
my                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 67ms]
mt                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 185ms]
ne                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 67ms]
nl                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 71ms]
no                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 66ms]
offers                  [Status: 301, Size: 227, Words: 9, Lines: 7, Duration: 10ms]
pa                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 61ms]
passwords               [Status: 301, Size: 230, Words: 9, Lines: 7, Duration: 11ms]
pda                     [Status: 301, Size: 222, Words: 9, Lines: 7, Duration: 62ms]
phone                   [Status: 301, Size: 226, Words: 9, Lines: 7, Duration: 9ms]
pixel                   [Status: 301, Size: 226, Words: 9, Lines: 7, Duration: 10ms]
pl                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 63ms]
policies                [Status: 301, Size: 229, Words: 9, Lines: 7, Duration: 9ms]
press                   [Status: 301, Size: 226, Words: 9, Lines: 7, Duration: 13ms]
preferences             [Status: 301, Size: 230, Words: 9, Lines: 7, Duration: 60ms]
privacy                 [Status: 301, Size: 228, Words: 9, Lines: 7, Duration: 10ms]
partners                [Status: 200, Size: 11243, Words: 422, Lines: 18, Duration: 876ms]
products                [Status: 301, Size: 227, Words: 9, Lines: 7, Duration: 62ms]
patents                 [Status: 302, Size: 0, Words: 1, Lines: 1, Duration: 906ms]
publications            [Status: 301, Size: 241, Words: 9, Lines: 7, Duration: 9ms]
publisher               [Status: 301, Size: 234, Words: 9, Lines: 7, Duration: 11ms]
ps                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 61ms]
pt                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 67ms]
related                 [Status: 301, Size: 228, Words: 9, Lines: 7, Duration: 10ms]
research                [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 11ms]
ro                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 67ms]
robots.txt              [Status: 200, Size: 7086, Words: 322, Lines: 283, Duration: 65ms]
reporting               [Status: 302, Size: 372, Words: 9, Lines: 7, Duration: 307ms]
ru                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 66ms]
sa                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 62ms]
s                       [Status: 301, Size: 220, Words: 9, Lines: 7, Duration: 64ms]
sd                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 64ms]
search                  [Status: 301, Size: 225, Words: 9, Lines: 7, Duration: 68ms]
services                [Status: 301, Size: 229, Words: 9, Lines: 7, Duration: 10ms]
sh                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 61ms]
shopping                [Status: 301, Size: 227, Words: 9, Lines: 7, Duration: 67ms]
reviews                 [Status: 302, Size: 259, Words: 9, Lines: 7, Duration: 717ms]
si                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 67ms]
sitemaps                [Status: 301, Size: 240, Words: 9, Lines: 7, Duration: 10ms]
sites                   [Status: 301, Size: 226, Words: 9, Lines: 7, Duration: 9ms]
sitemap.xml             [Status: 200, Size: 2055, Words: 188, Lines: 73, Duration: 65ms]
sk                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 63ms]
sl                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 70ms]
sm                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 65ms]
sms                     [Status: 302, Size: 231, Words: 9, Lines: 7, Duration: 59ms]
so                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 62ms]
space                   [Status: 301, Size: 226, Words: 9, Lines: 7, Duration: 14ms]
sports                  [Status: 301, Size: 225, Words: 9, Lines: 7, Duration: 68ms]
sq                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 68ms]
sr                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 65ms]
st                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 63ms]
stories                 [Status: 301, Size: 226, Words: 9, Lines: 7, Duration: 63ms]
story                   [Status: 301, Size: 224, Words: 9, Lines: 7, Duration: 62ms]
suggest                 [Status: 301, Size: 226, Words: 9, Lines: 7, Duration: 11ms]
support                 [Status: 301, Size: 224, Words: 9, Lines: 7, Duration: 62ms]
sv                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 70ms]
sw                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 62ms]
talk                    [Status: 301, Size: 229, Words: 9, Lines: 7, Duration: 10ms]
tags                    [Status: 302, Size: 263, Words: 9, Lines: 7, Duration: 63ms]
technology              [Status: 301, Size: 243, Words: 9, Lines: 7, Duration: 12ms]
te                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 65ms]
th                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 67ms]
toolbar                 [Status: 301, Size: 241, Words: 9, Lines: 7, Duration: 9ms]
tl                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 63ms]
tn                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 61ms]
to                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 62ms]
tools                   [Status: 302, Size: 226, Words: 9, Lines: 7, Duration: 65ms]
tr                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 78ms]
tt                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 60ms]
uk                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 69ms]
tw                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 143ms]
url                     [Status: 301, Size: 222, Words: 9, Lines: 7, Duration: 63ms]
video                   [Status: 301, Size: 222, Words: 9, Lines: 7, Duration: 14ms]
views                   [Status: 301, Size: 220, Words: 9, Lines: 7, Duration: 11ms]
vi                      [Status: 301, Size: 221, Words: 9, Lines: 7, Duration: 67ms]
webmaster               [Status: 301, Size: 231, Words: 9, Lines: 7, Duration: 10ms]
webmasters              [Status: 301, Size: 231, Words: 9, Lines: 7, Duration: 13ms]
wml                     [Status: 301, Size: 222, Words: 9, Lines: 7, Duration: 63ms]
xhtml                   [Status: 301, Size: 224, Words: 9, Lines: 7, Duration: 64ms]
:: Progress: [4750/4750] :: Job [1/1] :: 255 req/sec :: Duration: [0:00:14] :: Errors: 0 ::
```

## Estatísticas

- **Total de Testes**: 14
- **Testes Bem-sucedidos**: 12
- **Testes com Falha**: 3
- **Tempo Total de Execução**: 213 segundos
