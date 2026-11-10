%% dataimago-thesis.cls -- the dataimago house thesis class.
%%
%% Copyright 2026 dataimago
%%
%% This work may be distributed and/or modified under the conditions of the
%% LaTeX Project Public License, either version 1.3c of this license or (at
%% your option) any later version. The latest version of this license is in
%%   https://www.latex-project.org/lppl/
%% and version 1.3c or later is part of all distributions of LaTeX version
%% 2008 or later.
%%
%% This work has the LPPL maintenance status `maintained'.
%% The Current Maintainer of this work is dataimago.
%% This work consists of dataimago-thesis.cls and the files named in
%% classes/dataimago-thesis/README.md.
%%
%% Feature reference: the CU Boulder thesis class v1.14, by John P. Weiss
%% (1997), Bruce Fast, Steven V. Penton, E. Joshua Rigler, Hongcheng Ni and
%% Ken Anderson (v1.14). Feature reference only; no code derived. This class
%% was written from docs/house-class-spec.md and the LaTeX documentation.
%%
%% One class, many institutions: everything a school's guide decides lives in a
%% profile (profiles/<id>.yaml) compiled to <id>.cfg, which this class reads.
%% LPPL asks that a modified class carry another name; adapt a profile instead.
\NeedsTeXFormat{LaTeX2e}[2024-06-01]
\ProvidesClass{dataimago-thesis}[2026/11/08 v0.1.0 dataimago house thesis class]

\makeatletter
%% ------------------------------------------------------------------ cfg access
\providecommand\ThesisCfg[2]{\expandafter\gdef\csname thesis@c@#1\endcsname{#2}}
\newcommand\thesis@c[1]{\ifcsname thesis@c@#1\endcsname\csname thesis@c@#1\endcsname\fi}
\newcommand\thesis@cdef[1]{\ifcsname thesis@c@#1\endcsname TT\else FF\fi}
\newcommand\thesis@ifc[4]{%
  \edef\thesis@tmpa{\thesis@c{#1}}\def\thesis@tmpb{#2}%
  \ifx\thesis@tmpa\thesis@tmpb #3\else #4\fi}
\ExplSyntaxOn
\NewExpandableDocumentCommand\thesis@xstr{mmmm}{\str_if_eq:eeTF{#1}{#2}{#3}{#4}}
\ExplSyntaxOff
\newcommand\thesis@xifc[4]{\thesis@xstr{\thesis@c{#1}}{#2}{#3}{#4}}
\newcommand\thesis@ifon[3]{\thesis@ifc{#1}{true}{#2}{#3}}
\long\def\thesis@cfor#1#2#3{\edef\thesis@forlist{\thesis@c{#2}}\@for#1:=\thesis@forlist\do{#3}}
\newcommand\thesis@err[2]{\ClassError{dataimago-thesis}{#1}{#2}}
\newcommand\thesis@warn[1]{\ClassWarning{dataimago-thesis}{#1}}

%% ------------------------------------------------------------------ options
\def\thesis@profile{house}
\def\thesis@bookopts{}
\def\thesis@sizeopt{}
\newcommand\thesis@addbook[1]{\edef\thesis@bookopts{\thesis@bookopts,#1}}
\DeclareOption{draft}{\thesis@addbook{draft}\gdef\thesis@draftopt{true}}
\DeclareOption{final}{\thesis@addbook{final}}
\DeclareOption{fleqn}{\thesis@addbook{fleqn}}
\DeclareOption{leqno}{\thesis@addbook{leqno}}
\DeclareOption{openbib}{\thesis@addbook{openbib}}
\DeclareOption{10pt}{\def\thesis@sizeopt{10pt}}
\DeclareOption{11pt}{\def\thesis@sizeopt{11pt}}
\DeclareOption{12pt}{\def\thesis@sizeopt{12pt}}
\DeclareOption{openany}{\thesis@warn{The option `openany' is ignored: the profile field headings.chapter.newPage decides}}
\DeclareOption{openright}{\thesis@warn{The option `openright' is ignored: the profile field headings.chapter.newPage decides}}
\DeclareOption{twocolumn}{\thesis@err{The option `twocolumn' is not supported}{Theses are set in one column.}}
\DeclareOption{notitlepage}{\thesis@err{The option `notitlepage' is not supported}{The title page is generated from the profile.}}
\def\thesis@optparse#1=#2=#3\@nil{%
  \def\thesis@o{#1}\def\thesis@pk{profile}%
  \ifx\thesis@o\thesis@pk \def\thesis@profile{#2}\else
    \thesis@err{Unknown class option `#1'}{Supported: draft, final, fleqn, leqno, openbib, 10pt, 11pt, 12pt, profile=<id>.}%
  \fi}
\DeclareOption*{\expandafter\thesis@optparse\CurrentOption==\@nil}
\ProcessOptions\relax

%% ------------------------------------------------------------------ the profile
\InputIfFileExists{\thesis@profile.cfg}{}{%
  \thesis@err{Profile `\thesis@profile' not found: no \thesis@profile.cfg on the TeX search path}%
    {Generate it with: texlua thesis-profile.lua profiles \thesis@profile; then put the profiles directory on TEXINPUTS.}}

%% ------------------------------------------------------------------ base class
\def\thesis@sizeres{11pt}
\ifx\thesis@sizeopt\@empty
  \thesis@ifc{type.size}{10}{\def\thesis@sizeres{10pt}}{}
  \thesis@ifc{type.size}{11}{\def\thesis@sizeres{11pt}}{}
  \thesis@ifc{type.size}{12}{\def\thesis@sizeres{12pt}}{}
  \thesis@ifc{type.size}{10.5}{\thesis@warn{type.size 10.5 is not available in the book class; using 11pt}}{}
\else\let\thesis@sizeres\thesis@sizeopt\fi
\edef\thesis@loadopts{\thesis@sizeres}
\thesis@ifc{geometry.sides}{two}{\edef\thesis@loadopts{\thesis@loadopts,twoside}}{\edef\thesis@loadopts{\thesis@loadopts,oneside}}
\thesis@ifc{headings.chapter.newPage}{right}{\edef\thesis@loadopts{\thesis@loadopts,openright}}{\edef\thesis@loadopts{\thesis@loadopts,openany}}
\edef\thesis@loadopts{\thesis@loadopts\thesis@bookopts}
\LoadClass[\thesis@loadopts]{book}

\RequirePackage{iftex}
\RequirePackage{etoolbox}
\RequirePackage{xcolor}
\RequirePackage{amsmath,amssymb}
\RequirePackage{setspace}

%% ------------------------------------------------------------------ geometry
\newlength\thesis@gutter
\setlength\thesis@gutter{\thesis@c{geometry.binding.gutter}}
\newlength\thesis@mtop \newlength\thesis@mbottom \newlength\thesis@minside \newlength\thesis@moutside
\setlength\thesis@mtop{\thesis@c{geometry.margins.top}}
\setlength\thesis@mbottom{\thesis@c{geometry.margins.bottom}}
\setlength\thesis@minside{\thesis@c{geometry.margins.inside}}
\setlength\thesis@moutside{\thesis@c{geometry.margins.outside}}
\thesis@ifc{geometry.binding.side}{top}{\addtolength\thesis@mtop{\thesis@gutter}\setlength\thesis@gutter{0pt}}{}
\thesis@ifc{geometry.binding.side}{right}{%
  \thesis@ifc{geometry.sides}{two}{}{\addtolength\thesis@moutside{\thesis@gutter}\setlength\thesis@gutter{0pt}}}{}
\def\thesis@paperopts{letterpaper}
\thesis@ifc{geometry.paper}{a4}{\def\thesis@paperopts{a4paper}}{}
\thesis@ifc{geometry.paper}{custom}{\edef\thesis@paperopts{paperwidth=\thesis@c{geometry.paperWidth},paperheight=\thesis@c{geometry.paperHeight}}}{}
\RequirePackage[\thesis@paperopts,nohead,nofoot,
  top=\thesis@mtop,bottom=\thesis@mbottom,inner=\thesis@minside,outer=\thesis@moutside,
  bindingoffset=\thesis@gutter]{geometry}
\newlength\thesis@chaptertop
\setlength\thesis@chaptertop{\thesis@c{geometry.chapterOpening.extraTop}}
\newlength\thesis@numdist
\setlength\thesis@numdist{\thesis@c{geometry.headerFooter.numberDistance}}

%% ------------------------------------------------------------------ fonts
\thesis@ifc{type.math}{latex-default}{\RequirePackage{fontspec}}{\RequirePackage{unicode-math}}
\defaultfontfeatures[\rmfamily,\sffamily,\ttfamily]{Ligatures=TeX}
\thesis@ifc{type.main}{latex-default}{}{%
  \edef\thesis@tmpa{\thesis@c{type.main}}\expandafter\setmainfont\expandafter{\thesis@tmpa}}
\thesis@ifc{type.sans}{latex-default}{}{%
  \edef\thesis@tmpa{\thesis@c{type.sans}}\expandafter\setsansfont\expandafter{\thesis@tmpa}}
\thesis@ifc{type.mono}{latex-default}{}{%
  \edef\thesis@tmpa{\thesis@c{type.mono}}\expandafter\setmonofont\expandafter[Scale=MatchLowercase]{\thesis@tmpa}}
\thesis@ifc{type.math}{latex-default}{}{%
  \edef\thesis@tmpa{\thesis@c{type.math}}\expandafter\setmathfont\expandafter{\thesis@tmpa}}
%% R19: tagging needs LuaLaTeX; on XeLaTeX the request degrades to this warning, never a failure
\ifLuaTeX\else
  \thesis@ifc{accessibility.tagged}{on}{\thesis@warn{accessibility.tagged is on, but XeLaTeX cannot tag PDFs; building an untagged PDF. Use LuaLaTeX for tagged output (PDF/UA)}}{}
\fi
\ifLuaTeX\else
  \thesis@ifc{submission.pdfa}{none}{}{\thesis@warn{submission.pdfa is \thesis@c{submission.pdfa}, but PDF/A is not guaranteed on XeLaTeX (veraPDF finds file-trailer problems); use LuaLaTeX for a validated PDF/A file}}
\fi
%% M4: warn at load when the math font lacks an OpenType MATH table (LuaTeX only;
%% XeLaTeX cannot inspect the font table, so CI's pdffonts check is the guard there).
\ifLuaTeX
  \thesis@ifc{type.math}{latex-default}{}{%
    \directlua{
      local name = "\luaescapestring{\thesis@c{type.math}}"
      local file = fonts and fonts.names and fonts.names.resolve and fonts.names.resolve(name)
      local ok = nil
      if file and io then
        local f = io.open(file, "rb")
        if f then
          local head = f:read(12)
          if head and string.len(head) == 12 then
            local n = string.byte(head, 5) * 256 + string.byte(head, 6)
            ok = false
            for _ = 1, n do
              local rec = f:read(16)
              if rec and rec:sub(1, 4) == "MATH" then ok = true break end
            end
          end
          f:close()
        end
      end
      if ok == false then
        token.set_macro("thesis@mathfail", "1", "global")
      end
    }}
\fi
\ifdefined\thesis@mathfail\AtBeginDocument{\thesis@mathmissing}\fi
\def\thesis@mathmissing{%
  \thesis@warn{The math font `\thesis@c{type.math}' has no OpenType MATH table; equations will fall back to another math font}}
\thesis@ifc{type.emphasis}{bold}{\DeclareEmphSequence{\bfseries}}{}

%% ------------------------------------------------------------------ line spacing
\newcommand\thesis@fp[1]{\fpeval{#1}}
\begingroup
  \def\baselinestretch{1}\normalsize
  \xdef\thesis@singlepitch{\strip@pt\dimexpr\f@baselineskip\relax}
\endgroup
\def\thesis@computestretch{%
  \thesis@ifc{spacing.body.pitch}{}{%
    \thesis@ifc{spacing.body}{single}{\def\thesis@stretchval{1}}{%
      \thesis@ifc{spacing.body}{onehalf}{\def\thesis@stretchval{1.5}}{%
        \thesis@ifc{spacing.body}{double}{\def\thesis@stretchval{2}}{\edef\thesis@stretchval{\thesis@c{spacing.body}}}}}}{%
    \edef\thesis@stretchval{\thesis@fp{\strip@pt\dimexpr\thesis@c{spacing.body.pitch}\relax/\thesis@singlepitch}}}}
\thesis@computestretch
\def\thesis@single{\setstretch{1}}
\def\thesis@body{\setstretch{\thesis@stretchval}}
\def\thesis@setspacing#1#2{% key, then what: apply the named exception
  \thesis@ifc{spacing.#1}{single}{#2}{}}
\newcommand\thesis@spacingof[1]{%
  \thesis@ifc{spacing.#1}{single}{\thesis@single}{%
    \thesis@ifc{spacing.#1}{onehalf}{\setstretch{1.5}}{%
      \thesis@ifc{spacing.#1}{double}{\setstretch{2}}{\thesis@body}}}}
\renewenvironment{singlespace}{\par\thesis@single}{\par}
\renewenvironment{doublespace}{\par\thesis@body}{\par}

\setlength\parindent{\thesis@c{spacing.paragraph.indent}}
\setlength\parskip{\thesis@c{spacing.paragraph.skip}}

%% footnote, caption and heading sizes
\newcommand\thesis@fnsize{\thesis@c{type.footnoteSize}}
\newcommand\thesis@fnlead{\strip@pt\dimexpr 1.2\dimexpr\thesis@fnsize pt\relax\relax}
\renewcommand\footnotesize{%
  \@setfontsize\footnotesize{\thesis@fnsize}{\thesis@fnlead}%
  \abovedisplayskip 6\p@ \@plus2\p@ \@minus4\p@
  \abovedisplayshortskip \z@ \@plus\p@
  \belowdisplayshortskip 3\p@ \@plus\p@ \@minus2\p@
  \belowdisplayskip \abovedisplayskip}
%% setspace already sets footnotes single; only `inherit` needs work
\AddToHook{cmd/@makefntext/before}{\thesis@ifc{spacing.footnotes}{inherit}{\thesis@body}{}}
\AddToHook{env/quote/begin}{\thesis@setspacing{blockQuotes}{\thesis@single}}
\AddToHook{env/quotation/begin}{\thesis@setspacing{blockQuotes}{\thesis@single}}
\AddToHook{env/verse/begin}{\thesis@setspacing{blockQuotes}{\thesis@single}}
\AddToHook{env/longtable/begin}{\thesis@setspacing{tables}{\thesis@single}}
\AddToHook{env/tabular/begin}{\thesis@setspacing{tables}{\thesis@single}}
\AddToHook{env/Shaded/begin}{\thesis@setspacing{code}{\thesis@single}}
\AddToHook{env/verbatim/begin}{\thesis@setspacing{code}{\thesis@single}}

%% ------------------------------------------------------------------ numbering
\setcounter{secnumdepth}{\thesis@c{numbering.depth}}
\setcounter{tocdepth}{\thesis@c{toc.depth}}
\thesis@ifc{numbering.chapter}{roman}{\renewcommand\thechapter{\@Roman\c@chapter}}{}
\thesis@ifc{numbering.floats}{continuous}{%
  \counterwithout{figure}{chapter}\counterwithout{table}{chapter}}{}
\thesis@ifc{numbering.equations}{continuous}{\counterwithout{equation}{chapter}}{}
\thesis@ifc{numbering.footnotes}{per-chapter}{\counterwithin*{footnote}{chapter}}{}

%% ------------------------------------------------------------------ headings
\newcommand\thesis@hsize[1]{\strip@pt\dimexpr\thesis@c{#1}pt\relax}
\newcommand\thesis@hlead[1]{\strip@pt\dimexpr 1.2\dimexpr\thesis@c{#1}pt\relax\relax}
\newcommand\thesis@hfont[1]{%
  \normalfont\fontsize{\thesis@c{headings.#1.size}}{\thesis@hlead{headings.#1.size}}\selectfont
  \thesis@ifc{headings.#1.weight}{bold}{\bfseries}{}}
\newcommand\thesis@halign[1]{\thesis@ifc{headings.#1.align}{center}{\centering}{\raggedright}}
\newcommand\thesis@hcase[2]{\thesis@ifc{headings.#1.case}{upper}{\MakeUppercase{#2}}{#2}}
\def\thesis@sectionstyle#1#2{\thesis@halign{#1}\thesis@hfont{#1}\thesis@hcase{#1}{#2}}
\renewcommand\section{\@startsection{section}{1}{\z@}%
  {-3.25ex \@plus -1ex \@minus -.2ex}{1.5ex \@plus .2ex}{\thesis@hfont{section}\thesis@halign{section}\thesis@sectionuc{section}}}
\renewcommand\subsection{\@startsection{subsection}{2}{\z@}%
  {-3.25ex \@plus -1ex \@minus -.2ex}{1.0ex \@plus .2ex}{\thesis@hfont{subsection}\thesis@halign{subsection}\thesis@sectionuc{subsection}}}
\thesis@ifc{headings.level4.style}{inline}{%
  \renewcommand\subsubsection{\@startsection{subsubsection}{3}{\z@}%
    {3.25ex \@plus 1ex \@minus .2ex}{-1em}{\thesis@hfont{subsubsection}\thesis@sectionuc{subsubsection}}}}{%
  \renewcommand\subsubsection{\@startsection{subsubsection}{3}{\z@}%
    {-3.25ex \@plus -1ex \@minus -.2ex}{1.0ex \@plus .2ex}{\thesis@hfont{subsubsection}\thesis@halign{subsubsection}\thesis@sectionuc{subsubsection}}}}
%% the last style command receives the heading text as its argument
\newcommand\thesis@sectionuc[1]{\csname thesis@uc@#1\endcsname}
\def\thesis@uc@section#1{\thesis@hcase{section}{#1}}
\def\thesis@uc@subsection#1{\thesis@hcase{subsection}{#1}}
\def\thesis@uc@subsubsection#1{\thesis@hcase{subsubsection}{#1}}

\thesis@ifon{headings.part.allowed}{}{%
  \renewcommand\part{\thesis@err{`part' headings are not allowed by the profile \thesis@profile}%
    {Remove the part or set headings.part.allowed in the profile.}}}

\def\thesis@chalign{\thesis@halign{chapter}}
\def\thesis@chlabel{%
  \thesis@ifc{headings.chapter.label}{none}{}{%
    \thesis@ifc{headings.chapter.label}{number}{\thechapter\par\nobreak\vskip .5\baselineskip}{%
      \thesis@hcase{chapter}{\@chapapp}\space\thechapter\par\nobreak\vskip .5\baselineskip}}}
%% LaTeX 2026-11 redefines \chapter with its heading templates (and a \secdef that intercepts it) when
%% tagging is on, which would bypass \@makechapterhead. This class sets headings from the profile
%% itself, so it restores the classic \chapter (without \secdef) on every kernel version.
\renewcommand\chapter{\if@openright\cleardoublepage\else\clearpage\fi
  \thispagestyle{plain}\global\@topnum\z@\@afterindentfalse
  \@ifstar\@schapter{\@dblarg\@chapter}}

%% Chapter headings are tagged through the kernel's heading sockets (LaTeX 2026-11 and later, tagging on):
%% the classic \chapter restored above does not go through the heading templates, so the head opens and
%% closes the same Sect/H structure the kernel uses for \section. Without those sockets this is a no-op.
\newcommand\thesis@tagbegin[1]{%
  \ifdefined\UseTaggingSocket
    \par\UseTaggingSocket{sec/end}{0}\UseTaggingSocket{sec/begin}{{0}{}}%
    \UseTaggingSocket{sec/title/init}{0}\UseTaggingSocket{sec/title/begin}{{0}{#1}}%
  \fi}
\newcommand\thesis@tagend{\ifdefined\UseTaggingSocket\par\UseTaggingSocket{sec/title/end}\fi}
\def\@makechapterhead#1{%
  \vspace*{\thesis@chaptertop}%
  {\parindent\z@ \thesis@chalign \thesis@hfont{chapter}\interlinepenalty\@M
   \thesis@tagbegin{#1}%
   \ifnum \c@secnumdepth >\m@ne \thesis@chlabel\fi
   \thesis@hcase{chapter}{#1}\thesis@tagend\par\nobreak\vskip 2\baselineskip}}
\def\@makeschapterhead#1{%
  \vspace*{\thesis@chaptertop}%
  {\parindent\z@ \thesis@chalign \thesis@hfont{chapter}\interlinepenalty\@M
   \thesis@tagbegin{#1}%
   \thesis@hcase{chapter}{#1}\thesis@tagend\par\nobreak\vskip 2\baselineskip}}

\renewcommand\appendixname{\thesis@c{appendices.label}}
\g@addto@macro\appendix{%
  \thesis@ifc{appendices.numbering}{roman}{\renewcommand\thechapter{\@Roman\c@chapter}}{%
    \thesis@ifc{appendices.numbering}{arabic}{\renewcommand\thechapter{\@arabic\c@chapter}}{}}}
%% appendices.divider: Quarto writes one "Appendices" part entry (\addcontentsline{toc}{part}{Appendices})
%% for book.appendices; that entry is the divider. With divider: false the class drops it from the
%% contents (English title only; the per-appendix entries stay). With divider: true the entry reads
%% appendices.label (\appendixname) instead of Quarto's "Appendices".
\let\thesis@orig@lpart\l@part
\ExplSyntaxOn
\NewDocumentCommand\thesis@partunless{mmm}{\tl_if_in:nnTF{#1}{Appendices}{}{\thesis@orig@lpart{#1}{#2}}}
\NewDocumentCommand\thesis@partlabel{mmm}{\tl_if_in:nnTF{#1}{Appendices}{\thesis@orig@lpart{\appendixname}{#2}}{\thesis@orig@lpart{#1}{#2}}}
\ExplSyntaxOff
\renewcommand*\l@part[2]{\thesis@ifon{appendices.divider}{\thesis@partlabel{#1}{#2}{}}{\thesis@partunless{#1}{#2}{}}}

%% ------------------------------------------------------------------ page numbers
\def\thesis@none{none}
\def\thesis@numstate{none}
\def\thesis@numtext{}
\def\thesis@flag#1{\gdef\thesis@numstate{#1}\xdef\thesis@numtext{\thepage}%
  \xdef\thesis@numodd{\ifodd\c@page 1\else 0\fi}}
\def\ps@thesis@show{\let\@mkboth\@gobbletwo\def\@oddhead{\thesis@flag{show}}\let\@evenhead\@oddhead
  \def\@oddfoot{}\let\@evenfoot\@oddfoot}
\def\ps@thesis@bottom{\let\@mkboth\@gobbletwo\def\@oddhead{\thesis@flag{bottom}}\let\@evenhead\@oddhead
  \def\@oddfoot{}\let\@evenfoot\@oddfoot}
\def\ps@thesis@hide{\let\@mkboth\@gobbletwo\def\@oddhead{}\let\@evenhead\@oddhead
  \def\@oddfoot{}\let\@evenfoot\@oddfoot}
\thesis@ifc{pagenumber.chapterFirstPage}{hide}{\let\ps@plain\ps@thesis@hide}{%
  \thesis@ifc{pagenumber.chapterFirstPage}{bottom-center}{\let\ps@plain\ps@thesis@bottom}{\let\ps@plain\ps@thesis@show}}
\let\ps@empty\ps@thesis@hide
\newcommand\thesis@setmain{\pagestyle{thesis@show}}
\thesis@ifc{pagenumber.runningHead}{none}{}{\thesis@warn{pagenumber.runningHead: `\thesis@c{pagenumber.runningHead}' is not supported yet; no running head is printed}}
\newcommand\forcepageno{\thispagestyle{thesis@show}}
\let\OnePageChapter\forcepageno

\def\thesis@pos{\thesis@c{pagenumber.position}}
\def\thesis@pos@bottom{bottom-center}
\newcommand\thesis@drawnum{%
  \ifx\thesis@numstate\thesis@none\else
    \begingroup
      \ifx\thesis@numstate\thesis@pos@bottom\else\fi
      \edef\thesis@where{\thesis@c{pagenumber.position}}%
      \def\thesis@bot{bottom}%
      \ifx\thesis@numstate\thesis@bot \def\thesis@where{bottom-center}\fi
      \thesis@place
    \endgroup
    \global\let\thesis@numstate\thesis@none
  \fi}
\newlength\thesis@x \newlength\thesis@y
\newcommand\thesis@place{%
  \setlength\thesis@x{\dimexpr 1in+\hoffset\relax}%
  \if@twoside\ifnum\thesis@numodd=1 \addtolength\thesis@x{\oddsidemargin}\else\addtolength\thesis@x{\evensidemargin}\fi
  \else\addtolength\thesis@x{\oddsidemargin}\fi
  \def\thesis@top{top-}\def\thesis@isleft{left}\def\thesis@isright{right}\def\thesis@iscenter{center}%
  \edef\thesis@kind{\expandafter\thesis@lastword\thesis@where-\@nil}%
  \edef\thesis@vert{\expandafter\thesis@firstword\thesis@where-\@nil}%
  \def\thesis@anchor{b}%
  \ifx\thesis@kind\thesis@iscenter \addtolength\thesis@x{.5\textwidth}\else
    \ifx\thesis@kind\thesis@isright \addtolength\thesis@x{\textwidth}\def\thesis@anchor{rb}\else\def\thesis@anchor{lb}\fi\fi
  \def\thesis@istop{top}%
  \ifx\thesis@vert\thesis@istop \setlength\thesis@y{\dimexpr -\thesis@numdist\relax}\else
    \setlength\thesis@y{\dimexpr -\paperheight+\thesis@numdist\relax}\fi
  \unitlength=1sp
  \put(\number\thesis@x,\number\thesis@y){\csname thesis@mkbox@\thesis@anchor\endcsname{\normalfont\normalsize\thesis@numtext}}}
\def\thesis@mkbox@b#1{\makebox(0,0)[b]{#1}}
\def\thesis@mkbox@lb#1{\makebox(0,0)[lb]{#1}}
\def\thesis@mkbox@rb#1{\makebox(0,0)[rb]{#1}}
\def\thesis@firstword#1-#2\@nil{#1}
\def\thesis@lastword#1-#2-\@nil{#2}
\AddToHook{shipout/foreground}{\thesis@drawnum}

%% ------------------------------------------------------------------ captions
\newlength\thesis@capskip \setlength\thesis@capskip{10\p@}
\long\def\@makecaption#1#2{%
  \thesis@ifc{floats.captionPosition.\@captype}{above}{}{\vskip\thesis@capskip}%
  \sbox\@tempboxa{\thesis@capfont #1\thesis@c{floats.labelSeparator}#2}%
  \ifdim \wd\@tempboxa >\hsize
    {\thesis@capfont\thesis@spacingof{captions}#1\thesis@c{floats.labelSeparator}#2\par}%
  \else
    \global \@minipagefalse
    \hb@xt@\hsize{\hfil\box\@tempboxa\hfil}%
  \fi
  \thesis@ifc{floats.captionPosition.\@captype}{above}{\vskip\thesis@capskip}{}}
\def\thesis@capfont{\normalfont\fontsize{\thesis@c{type.captionSize}}{\strip@pt\dimexpr 1.2\dimexpr\thesis@c{type.captionSize}pt\relax\relax}\selectfont}
\providecommand\ThesisAux[2]{\expandafter\gdef\csname thesis@aux@#1\endcsname{#2}}
%% which lists have entries: noted while \caption runs, written to the aux file at the end,
%% read back by the next pass (\ThesisAux), so `mode: auto` needs no manual flag
\AddToHook{cmd/caption/before}{\thesis@notecaption}
\def\thesis@notecaption{\ifdefined\@captype\expandafter\gdef\csname thesis@seen@\@captype\endcsname{1}\fi}
\AtEndDocument{\if@filesw
  \immediate\write\@mainaux{\string\ThesisAux{seen.lof}{\ifcsname thesis@seen@figure\endcsname 1\else 0\fi}}%
  \immediate\write\@mainaux{\string\ThesisAux{seen.lot}{\ifcsname thesis@seen@table\endcsname 1\else 0\fi}}\fi}
\providecommand\ThesisAux[2]{\expandafter\gdef\csname thesis@aux@#1\endcsname{#2}}
%% The Quarto filter knows which floats have captions and says so (\thesishaslists); that wins over
%% the aux-file detection above, which longtable's caption path cannot feed.
\newcommand\thesishaslists[2]{%
  \expandafter\gdef\csname thesis@given@lof\endcsname{#1}\expandafter\gdef\csname thesis@given@lot\endcsname{#2}}
\newcommand\thesis@seen[1]{\ifcsname thesis@given@#1\endcsname\csname thesis@given@#1\endcsname\else\thesis@aux{seen.#1}\fi}
\newcommand\thesis@aux[1]{\ifcsname thesis@aux@#1\endcsname\csname thesis@aux@#1\endcsname\else 0\fi}

\AddToHook{begindocument/before}{%
  \ifdef\captionsetup{%
    \DeclareCaptionLabelSeparator{thesis}{\thesis@c{floats.labelSeparator}}%
    \DeclareCaptionFont{thesiscap}{\thesis@capfont\thesis@spacingof{captions}}%
    \captionsetup{labelsep=thesis,font=thesiscap}%
    \thesis@ifc{floats.captionPosition.table}{above}{\captionsetup[table]{position=top}}{\captionsetup[table]{position=bottom}}%
    \thesis@ifc{floats.captionPosition.figure}{below}{\captionsetup[figure]{position=bottom}}{\captionsetup[figure]{position=top}}}{}}

%% bibliography and hanging indent for Pandoc/citeproc references
\AddToHook{begindocument/before}{%
  \ifdef\cslhangindent{\setlength\cslhangindent{\thesis@c{bibliography.hangingIndent}}}{}}
\AddToHook{env/CSLReferences/begin}{\thesis@setspacing{bibliography.within}{\thesis@single}}
\renewcommand\bibname{\thesis@c{bibliography.heading}}
\AddToHook{env/CSLReferences/after}{\setlength\itemsep{\thesis@c{spacing.bibliography.between}}}

%% ------------------------------------------------------------------ metadata setters
\newcommand\thesis@def[2]{\expandafter\gdef\csname thesis@m@#1\endcsname{#2}}
\newcommand\thesis@m[1]{\ifcsname thesis@m@#1\endcsname\csname thesis@m@#1\endcsname\fi}
\newcommand\thesissubtitle[1]{\thesis@def{subtitle}{#1}}
\newcommand\thesisauthorfamily[1]{\thesis@def{family}{#1}}
\newcommand\thesisauthorgiven[1]{\thesis@def{given}{#1}}
\newcommand\thesisyear[1]{\thesis@def{year}{#1}}
\newcommand\thesisdegree[1]{\thesis@def{degree}{#1}}
\newcommand\thesisdegreeabbr[1]{\thesis@def{degreeabbr}{#1}}
\newcommand\thesisfield[1]{\thesis@def{field}{#1}}
\newcommand\thesisdocumenttype[1]{\thesis@def{type}{#1}}
\newcommand\thesisdepartment[1]{\thesis@def{department}{#1}}
\newcommand\thesisinstitution[1]{\thesis@def{institution}{#1}}
\newcommand\thesisgradschool[1]{\thesis@def{gradschool}{#1}}
\newcommand\thesisirb[1]{\thesis@def{irb}{#1}}
\newcommand\thesisdate[2]{\thesis@def{datemonthyear}{#1}\thesis@def{dateyear}{#2}}
\newcommand\thesisdraft[1]{\def\thesis@draftopt{#1}}
\newcommand\thesisfrontmode[1]{\def\thesis@frontmode{#1}}
\def\thesis@frontmode{full}
\def\thesis@draftopt{false}
\let\thesis@person\@gobblefour
\def\thesis@advisors{}\def\thesis@members{}\def\thesis@previous{}\def\thesis@keywords{}\def\thesis@pdfkeywords{}
\newcommand\thesisaddadvisor[4]{\g@addto@macro\thesis@advisors{\thesis@person{#1}{#2}{#3}{#4}}}
\newcommand\thesisaddmember[4]{\g@addto@macro\thesis@members{\thesis@person{#1}{#2}{#3}{#4}}}
\newcommand\thesisaddprevious[1]{\g@addto@macro\thesis@previous{\thesis@prevline{#1}}}
\newcommand\thesisaddkeyword[1]{%
  \ifx\thesis@pdfkeywords\@empty\g@addto@macro\thesis@pdfkeywords{#1}\else\g@addto@macro\thesis@pdfkeywords{, #1}\fi}
\newcommand\thesisabstract[1]{\long\gdef\thesis@abstracttext{#1}}
\long\def\thesisfront#1#2{\expandafter\long\expandafter\gdef\csname thesis@front@#1\endcsname{#2}}
\def\thesis@abstracttext{}

%% slots
\newcommand\thesisslot[1]{\ifcsname thesis@s@#1\endcsname\csname thesis@s@#1\endcsname\fi}
\newcommand\thesis@ldef[2]{\expandafter\edef\csname thesis@s@#1\endcsname{#2}}
\newcommand\thesis@sdef[2]{\expandafter\xdef\csname thesis@s@#1\endcsname{#2}}
\newcommand\thesis@setslots{%
  \thesis@sdef{title}{\@title}\thesis@sdef{author}{\@author}%
  \edef\thesis@tmpa{\thesis@m{family}}%
  \ifx\thesis@tmpa\@empty \thesis@sdef{authorInverted}{\@author}\else
    \thesis@sdef{authorInverted}{\thesis@m{family}, \thesis@m{given}}\fi
  \thesis@sdef{degreeName}{\thesis@m{degree}}\thesis@sdef{degreeAbbr}{\thesis@m{degreeabbr}}%
  \thesis@sdef{field}{\thesis@m{field}}\thesis@sdef{documentType}{\thesis@m{type}}%
  \thesis@sdef{department}{\thesis@m{department}}%
  \edef\thesis@tmpa{\thesis@m{institution}}%
  \ifx\thesis@tmpa\@empty\thesis@sdef{institution}{\thesis@c{institution.name}}\else\thesis@sdef{institution}{\thesis@m{institution}}\fi
  \edef\thesis@tmpa{\thesis@m{gradschool}}%
  \ifx\thesis@tmpa\@empty\thesis@sdef{graduateSchool}{\thesis@c{institution.graduateSchool}}\else\thesis@sdef{graduateSchool}{\thesis@m{gradschool}}\fi
  \edef\thesis@tmpa{\thesis@m{year}}%
  \ifx\thesis@tmpa\@empty\thesis@sdef{year}{\thesis@m{dateyear}}\else\thesis@sdef{year}{\thesis@m{year}}\fi
  \thesis@sdef{date}{\@date}\thesis@sdef{irb}{\thesis@m{irb}}%
  \thesis@firstadvisor}
\def\thesis@firstadvisor{%
  \thesis@sdef{advisorName}{}\thesis@sdef{advisorTitle}{}%
  \begingroup\def\thesis@fadone{x}%
  \def\thesis@person##1##2##3##4{\ifx\thesis@fadone\relax\else
    \thesis@sdef{advisorName}{##1}\thesis@sdef{advisorTitle}{##2}\let\thesis@fadone\relax\fi}%
  \thesis@advisors\endgroup}

%% required-field checks (R5): errors name the author-facing key
\newcommand\thesis@require[3]{% macro-name key file
  \edef\thesis@tmpa{\thesis@m{#1}}\ifx\thesis@tmpa\@empty
    \thesis@err{The #2 is missing}{Set it in #3 (the thesis class cannot build a title page without it).}\fi}
\let\thesis@kerneltitle\@title\let\thesis@kernelauthor\@author % the kernel's "no \title given" defaults
\newcommand\thesis@checkfields{%
  \ifx\@title\thesis@kerneltitle\thesis@err{book.title is missing}{Set `title:` under `book:` in _quarto.yml.}\fi
  \ifx\@title\@empty\thesis@err{book.title is missing}{Set `title:` under `book:` in _quarto.yml.}\fi
  \ifx\@author\thesis@kernelauthor\thesis@err{book.author is missing}{Set `author:` under `book:` in _quarto.yml.}\fi
  \ifx\@author\@empty\thesis@err{book.author is missing}{Set `author:` under `book:` in _quarto.yml.}\fi
  \thesis@require{degree}{thesis.degree.name}{_quarto.yml}%
  \thesis@require{department}{thesis.department}{_quarto.yml}%
  \edef\thesis@tmpa{\thesis@m{institution}\thesis@c{institution.name}}%
  \ifx\thesis@tmpa\@empty\thesis@err{thesis.institution is missing}{Set `institution:` under `thesis:` in _quarto.yml.}\fi
  \ifx\thesis@advisors\@empty\thesis@err{thesis.advisors is missing}{Set at least one advisor under `thesis:` in _quarto.yml.}\fi
  \ifx\thesis@members\@empty\thesis@err{thesis.committee is missing}{Set the committee under `thesis:` in _quarto.yml.}\fi
  \ifx\thesis@abstracttext\@empty\thesis@err{The abstract is missing}{Add an `abstract:` field to the front matter of index.qmd.}\fi}

%% ------------------------------------------------------------------ the abstract environment
%% abstract.heading (unset: Abstract; "" omits it), abstract.align (center | left),
%% abstract.headerWeight (bold | normal); the defaults are the house output
\ifcsname thesis@c@frontmatter.abstract.heading\endcsname
  \protected@edef\thesis@abshead{\thesis@c{frontmatter.abstract.heading}}
\else\def\thesis@abshead{Abstract}\fi
\def\thesis@absalign{\thesis@ifc{frontmatter.abstract.align}{left}{\raggedright}{\centering}}
\def\thesis@absweight{\thesis@ifc{frontmatter.abstract.headerWeight}{normal}{\normalfont}{\bfseries}}
\newenvironment{abstract}{\thesis@abstractbegin}{\thesis@abstractend}
\def\thesis@abstractbegin{%
  \thesis@startpage{abstract}%
  {\thesis@absalign\thesis@single\thesis@absweight\thesis@c{frontmatter.abstract.header}\par}%
  \vskip 1.5\baselineskip
  \ifx\thesis@abshead\@empty\else{\thesis@absalign\bfseries\thesis@abshead\par}\vskip \baselineskip\fi
  \thesis@spacingof{abstract}}
\def\thesis@abstractend{\par}

%% ------------------------------------------------------------------ front matter
\newif\ifthesis@tocdone
\newcommand\thesis@startpage[1]{%
  \clearpage\thispagestyle{thesis@show}%
  \thesis@hidefirst{#1}}
\newcommand\thesis@hidefirst[1]{%
  \def\thesis@this{#1}%
  \thesis@cfor{\thesis@h}{pagenumber.front.hideOn}{\ifx\thesis@h\thesis@this\thispagestyle{thesis@hide}\fi}}
\newcommand\thesis@tocentry[2]{%
  \thesis@ifc{toc.includesFrontmatter}{all}{\addcontentsline{toc}{chapter}{#2}}{%
    \thesis@ifc{toc.includesFrontmatter}{after}{\ifthesis@tocdone\addcontentsline{toc}{chapter}{#2}\fi}{}}}
%% a chapter-style front page: heading, optional contents entry, first-page number rule
\newcommand\thesis@fmchapter[2]{% id heading
  \clearpage
  \phantomsection
  \chapter*{\thesis@titlecase{#2}}%
  \thesis@tocentry{#1}{#2}%
  \thesis@hidefirst{#1}}
\newcommand\thesis@titlecase[1]{\thesis@ifc{frontmatter.titlesCase}{upper}{\MakeUppercase{#1}}{#1}}

\newcommand\thesis@frontprose[2]{% id default-heading
  \ifcsname thesis@front@#1\endcsname
    \thesis@fmchapter{#1}{#2}%
    \csname thesis@front@#1\endcsname\par
  \fi}
\newcommand\thesis@dedication{%
  \ifcsname thesis@front@dedication\endcsname
    \thesis@startpage{dedication}\vspace*{.25\textheight}%
    {\centering\thesis@single
     \thesis@ifc{frontmatter.dedication.heading}{}{}{{\bfseries\thesis@c{frontmatter.dedication.heading}\par}\vskip\baselineskip}%
     \csname thesis@front@dedication\endcsname\par}%
  \fi}

\newcommand\thesis@roletext[1]{\thesis@xstr{#1}{chair}{Chair}{\thesis@xstr{#1}{co-chair}{Co-chair}{\thesis@xstr{#1}{member}{}{#1}}}}
\def\thesis@memberline#1#2#3#4{%
  \begingroup
  \thesis@ldef{name}{#1}\thesis@ldef{title}{#2}\thesis@ldef{role}{#3}\thesis@ldef{affiliation}{#4}%
  \par\noindent{\thesis@c{frontmatter.committee.format}%
  \edef\thesis@tmpa{\thesis@roletext{#3}}\ifx\thesis@tmpa\@empty\else, \thesis@roletext{#3}\fi}%
  \endgroup}
\newcommand\thesis@committeelist{{\thesis@single\let\thesis@person\thesis@memberline
  \thesis@advisors\thesis@members\par}}
\def\thesis@prevline#1{\par #1}

\newcommand\thesis@titlecasefor[1]{\thesis@xifc{frontmatter.titlePage.case}{upper}{\MakeUppercase{#1}}{#1}}
\newcommand\thesis@titleblock[1]{%
  \csname thesis@tb@#1\endcsname}
\def\thesis@tb@title{{\Large\bfseries\protected@edef\thesis@tmpa{\thesis@titlecasefor{\@title}}\thesis@tmpa\par}%
  \ifx\thesis@m@subtitle\relax\else\edef\thesis@tmpa{\thesis@m{subtitle}}\ifx\thesis@tmpa\@empty\else
    \vskip .5\baselineskip{\large\thesis@m{subtitle}\par}\fi\fi\vskip 2\baselineskip}
\def\thesis@tb@byline{{\thesis@c{frontmatter.titlePage.byline}\par}\vskip 1.5\baselineskip}
\def\thesis@tb@previousDegrees{\thesis@ifon{frontmatter.titlePage.previousDegrees}{{\thesis@previous\par}\vskip 2\baselineskip}{}}
\def\thesis@tb@statement{{\thesis@titlecasefor{\thesis@c{frontmatter.titlePage.statement}}\par}\vskip 2\baselineskip}
\def\thesis@tb@date{\thesis@ifc{frontmatter.titlePage.date}{none}{}{%
  \thesis@ifc{frontmatter.titlePage.date}{month-year}{\thesis@m{datemonthyear}}{\thesisslot{year}}\par\vskip 2\baselineskip}}
\def\thesis@tb@committee{\vfill{\raggedleft\thesis@c{frontmatter.committee.heading}:\par\thesis@committeelist\par}}
\newcommand\thesis@titlepage{%
  \clearpage
  \ifthesis@titlecounts\else\pagenumbering{gobble}\fi
  \thispagestyle{thesis@hide}%
  \thesis@ifon{pagenumber.front.titleShown}{\thispagestyle{thesis@show}}{}%
  \begingroup\thesis@single\centering\vspace*{.5in}%
  \thesis@cfor{\thesis@b}{frontmatter.titlePage.layout}{\thesis@titleblock{\thesis@b}}%
  \par\endgroup
  \clearpage
  \ifthesis@titlecounts\else\thesis@frontnumbering\fi}
\newif\ifthesis@titlecounts
\thesis@ifon{pagenumber.front.titleCounts}{\thesis@titlecountstrue}{\thesis@titlecountsfalse}
\newcommand\thesis@frontnumbering{%
  \thesis@ifc{pagenumber.front.style}{none}{\pagenumbering{gobble}}{%
    \thesis@ifc{pagenumber.front.style}{arabic}{\pagenumbering{arabic}}{\pagenumbering{roman}}}}

\newcommand\thesis@page@title{\thesis@titlepage}
\newcommand\thesis@page@copyright{%
  \thesis@ifon{frontmatter.copyright.enabled}{%
    \thesis@startpage{copyright}\vspace*{\fill}{\centering\thesis@single\thesis@c{frontmatter.copyright.template}\par}\vspace*{.4\textheight}}{}}
\newcommand\thesis@page@approval{%
  \thesis@ifon{frontmatter.approval.enabled}{%
    \thesis@startpage{approval}{\thesis@single\centering\thesis@c{frontmatter.approval.statement}\par}\vskip 2\baselineskip
    \begingroup\thesis@single\let\thesis@person\thesis@signline\thesis@advisors\thesis@members\endgroup
    \thesis@ifon{frontmatter.approval.dateLine}{\vskip 2\baselineskip\noindent Date:\ \rule{2in}{.4pt}\par}{}%
    \thesis@ifon{frontmatter.approval.irbLine}{\edef\thesis@tmpa{\thesis@m{irb}}\ifx\thesis@tmpa\@empty\else\vskip\baselineskip\noindent IRB protocol: \thesis@m{irb}\par\fi}{}}{}}
\def\thesis@signline#1#2#3#4{\vskip 2\baselineskip\noindent\rule{3in}{.4pt}\par\noindent#1, #2\edef\thesis@tmpa{\thesis@roletext{#3}}\ifx\thesis@tmpa\@empty\else\ (\thesis@roletext{#3})\fi\par}
\newcommand\thesis@page@committee{%
  \thesis@ifc{frontmatter.committee.placement}{separate-page}{%
    \thesis@startpage{committee}{\centering\bfseries\thesis@c{frontmatter.committee.heading}\par}\vskip\baselineskip
    \thesis@committeelist}{}}
\newcommand\thesis@page@abstract{\begin{abstract}\thesis@abstracttext\end{abstract}}
\newcommand\thesis@page@dedication{\thesis@dedication}
\newcommand\thesis@page@acknowledgments{\thesis@frontprose{acknowledgments}{\thesis@c{frontmatter.acknowledgments.heading}}}
\newcommand\thesis@page@preface{\thesis@frontprose{preface}{Preface}}
\newcommand\thesis@page@abbreviations{\thesis@frontprose{abbreviations}{List of Abbreviations}}
\newcommand\thesis@page@symbols{\thesis@frontprose{symbols}{List of Symbols}}

%% contents and lists
\newcommand\thesis@leaders{\thesis@ifc{toc.leaders}{none}{\hfill}{\leaders\hbox{$\m@th\mkern\@dotsep mu\hbox{.}\mkern\@dotsep mu$}\hfill}}
\def\thesis@tocgap{0pt}
%% Contents lines. LaTeX 2026-11 wraps the text, leaders and page number of a line in hooks and tagging
%% sockets so the tagged contents get TOCI children (Reference, Lbl, artifact leaders); this line
%% layout keeps those calls, which are no-ops on kernels without them.
\providecommand\@contentsline@destination{}
\newcommand\thesis@usetochook[5]{\IfHookExistsTF{contentsline/#1}{\UseHookWithArguments{contentsline/#1}{4}{#2}{#3}{#4}{#5}}{}}
\newcommand\thesis@tocfmt[2]{\ifcsname contentsline@text@#1@format\endcsname\csname contentsline@text@#1@format\endcsname{#2}\else#2\fi}
\def\thesis@dottedtocline#1#2#3#4#5{%
  \ifnum #1>\c@tocdepth \else
    \vskip \thesis@tocgap\relax
    {\leftskip #2\relax \rightskip \@tocrmarg \parfillskip -\rightskip
     \parindent #2\relax\@afterindenttrue
     \interlinepenalty\@M
     \leavevmode
     \@tempdima #3\relax
     \advance\leftskip \@tempdima \null\nobreak\hskip -\leftskip
     \thesis@usetochook{text/before}{#1}{#4}{#5}{\@contentsline@destination}%
     \thesis@tocfmt{#1}{#4}%
     \thesis@usetochook{text/after}{#1}{#4}{#5}{\@contentsline@destination}%
     \nobreak
     \ifdefined\UseTaggingSocket\UseTaggingSocket{toc/leaders/before}\fi
     \ifdefined\SuspendTagging\SuspendTagging{toc/leaders}\fi
     \thesis@leaders\hfill
     \ifdefined\ResumeTagging\ResumeTagging{toc/leaders}\fi
     \ifdefined\UseTaggingSocket\UseTaggingSocket{toc/leaders/after}\fi
     \nobreak
     \hb@xt@\@pnumwidth{\hss
       \thesis@usetochook{page/before}{#1}{#4}{#5}{\@contentsline@destination}%
       #5%
       \thesis@usetochook{page/after}{#1}{#4}{#5}{\@contentsline@destination}}%
     \par}%
  \fi}
\renewcommand*\l@chapter[2]{\addpenalty{-\@highpenalty}\thesis@dottedtocline{0}{0em}{1.5em}{#1}{#2}}
\renewcommand*\l@section{\thesis@dottedtocline{1}{1.5em}{2.3em}}
\renewcommand*\l@subsection{\thesis@dottedtocline{2}{3.8em}{3.2em}}
\renewcommand*\l@subsubsection{\thesis@dottedtocline{3}{7.0em}{4.1em}}
\renewcommand*\l@paragraph{\thesis@dottedtocline{4}{10em}{5em}}
\renewcommand*\l@figure{\thesis@dottedtocline{0}{0em}{3em}}
\renewcommand*\l@table{\thesis@dottedtocline{0}{0em}{3em}}
\newcommand\thesis@spaceoflist[1]{% toc or lists
  \thesis@ifc{spacing.#1}{double}{\thesis@body\def\thesis@tocgap{0pt}}{%
    \thesis@ifc{spacing.#1}{single}{\thesis@single\def\thesis@tocgap{0pt}}{\thesis@single\def\thesis@tocgap{\baselineskip}}}}
\newcommand\thesis@labelrow[1]{%
  \thesis@ifon{toc.columnLabels}{{\noindent\bfseries #1\hfill Page\par}\vskip .5\baselineskip}{}}
%% contents and list headings: the profile's string when set, else the language's name
\newcommand\thesis@listname[2]{\thesis@xifc{#1}{}{#2}{\thesis@c{#1}}}
\renewcommand\tableofcontents{%
  \thesis@fmchapter{toc}{\thesis@listname{frontmatter.toc.heading}{\contentsname}}\@mkboth{\contentsname}{\contentsname}%
  \begingroup\thesis@spaceoflist{toc}\thesis@labelrow{Chapter}\@starttoc{toc}\endgroup
  \global\thesis@tocdonetrue}
\newcommand\thesis@listof[4]{% ext type title label
  \thesis@ifc{frontmatter.lists.#2.mode}{never}{}{%
    \thesis@ifc{frontmatter.lists.#2.mode}{auto}{\ifnum\thesis@seen{#1}=0 \else\thesis@dolist{#1}{#2}{#4}{#3}\fi}{\thesis@dolist{#1}{#2}{#4}{#3}}}}
\def\thesis@lbl@lof{Figure}\def\thesis@lbl@lot{Table}
\newcommand\thesis@dolist[4]{% ext key title type
  \thesis@fmchapter{#2}{#3}%
  \begingroup\thesis@spaceoflist{lists}\thesis@labelrow{\csname thesis@lbl@#2\endcsname}%
  \protected@write\@auxout{}{\string\ThesisAux{#1.start}{\the\c@page}}%
  \thesis@listfirstpage{#2}%
  \@starttoc{#1}%
  \protected@write\@auxout{}{\string\ThesisAux{#1.end}{\the\c@page}}%
  \endgroup}
\newcommand\thesis@listfirstpage[1]{%
  \thesis@ifc{frontmatter.lists.#1.numberFirstPage}{show}{\thispagestyle{thesis@show}}{%
    \thesis@ifc{frontmatter.lists.#1.numberFirstPage}{hide}{\thispagestyle{thesis@hide}}{%
      \ifnum\thesis@aux{#1.end}=\thesis@aux{#1.start}\relax\ifnum\thesis@aux{#1.end}>0 \thispagestyle{thesis@show}\fi\fi}}}
\renewcommand\listoffigures{\thesis@listof{lof}{lof}{figure}{\thesis@listname{frontmatter.lists.lof.heading}{\listfigurename}}}
\renewcommand\listoftables{\thesis@listof{lot}{lot}{table}{\thesis@listname{frontmatter.lists.lot.heading}{\listtablename}}}
\newcommand\thesis@page@toc{\tableofcontents}
\newcommand\thesis@page@lof{\listoffigures}
\newcommand\thesis@page@lot{\listoftables}

\newcommand\thesisfrontmatter{%
  \thesis@ifc{\thesis@frontmode}{none}{}{}%
  \def\thesis@fm@none{none}%
  \ifx\thesis@frontmode\thesis@fm@none\else
    \thesis@checkfields
    \thesis@setslots
    \frontmatter
    \thesis@frontnumbering
    \global\thesis@tocdonefalse
    \thesis@cfor{\thesis@p}{frontmatter.order}{\csname thesis@page@\thesis@p\endcsname}%
    \clearpage
  \fi}
\AddToHook{cmd/frontmatter/after}{\pagestyle{thesis@show}}
\AddToHook{cmd/mainmatter/after}{\pagestyle{thesis@show}\setcounter{page}{\thesis@c{pagenumber.main.start}}}

%% ------------------------------------------------------------------ landscape
\thesis@ifc{appendices.placement}{before-bibliography}{\thesis@warn{appendices.placement: before-bibliography cannot be enforced; Quarto sets the chapter order (references, then appendices)}}{}
\RequirePackage{pdflscape}
\thesis@ifc{landscape.pageNumber}{rotated-with-text}{\thesis@warn{landscape.pageNumber: rotated-with-text is not implemented; the number stays upright on the page}}{}
\thesis@ifc{landscape.margins.top}{}{}{\thesis@warn{landscape.margins is not implemented yet; landscape pages use the page margins}}

%% ------------------------------------------------------------------ links and metadata (R18)
\AtEndPreamble{%
  \IfPackageLoadedTF{hyperref}{}{\RequirePackage{hyperref}}}
\AddToHook{begindocument/before}{%
  \IfPackageLoadedTF{hyperref}{%
    \thesis@ifc{submission.links}{boxes}{}{%
      \thesis@ifc{submission.links}{underline}{%
        \hypersetup{colorlinks=false,pdfborder={0 0 1},pdfborderstyle={/S/U/W 1},allbordercolors=black}}{%
      \thesis@ifc{submission.links}{color}{%
        \definecolor{thesislink}{HTML}{\thesis@c{submission.linkColor}}%
        \hypersetup{colorlinks=true,linkcolor=thesislink,citecolor=thesislink,urlcolor=thesislink,filecolor=thesislink}}{%
        \hypersetup{hidelinks}}}}%
    \edef\thesis@hyopts{bookmarksnumbered=true,pdfusetitle,pdfdisplaydoctitle=true,bookmarksopen=\thesis@c{submission.bookmarksOpen}}%
    \expandafter\hypersetup\expandafter{\thesis@hyopts}%
    \thesis@setslots
    \hypersetup{pdfsubject={\thesis@m{degree}, \thesis@m{field}, \thesisslot{institution}, \thesisslot{year}}}%
    \ifx\thesis@pdfkeywords\@empty\else\hypersetup{pdfkeywords={\thesis@pdfkeywords}}\fi
    \IfPackageLoadedTF{bookmark}{%
      \edef\thesis@bmopts{depth=\thesis@c{submission.bookmarkDepth},open=\thesis@c{submission.bookmarksOpen}}%
      \expandafter\bookmarksetup\expandafter{\thesis@bmopts}}{}%
  }{}}
\AddToHook{begindocument/before}{%
  \setcounter{secnumdepth}{\thesis@c{numbering.depth}}%
  \setcounter{tocdepth}{\thesis@c{toc.depth}}%
  \ifdefined\thesis@bodydone\else\let\thesis@bodydone\relax\thesis@body\fi}

%% draft marking (thesis.draft)
\AddToHook{shipout/foreground}{%
  \def\thesis@isdraft{true}\ifx\thesis@draftopt\thesis@isdraft
    \unitlength=1sp\put(\number\dimexpr 1in\relax,-\number\dimexpr\paperheight-.25in\relax){\normalfont\sffamily\footnotesize DRAFT}\fi}

\makeatother
\endinput
