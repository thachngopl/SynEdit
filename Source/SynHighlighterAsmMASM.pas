{-------------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: SynHighlighterASM.pas, released 2000-04-18.
The Original Code is based on the nhAsmSyn.pas file from the
mwEdit component suite by Martin Waldenburg and other developers, the Initial
Author of this file is Nick Hoddinott.
Unicode translation by Ma�l H�rz.
All Rights Reserved.

Contributors to the SynEdit and mwEdit projects are listed in the
Contributors.txt file.

Alternatively, the contents of this file may be used under the terms of the
GNU General Public License Version 2 or later (the "GPL"), in which case
the provisions of the GPL are applicable instead of those above.
If you wish to allow use of your version of this file only under the terms
of the GPL and not to allow others to use your version of this file
under the MPL, indicate your decision by deleting the provisions above and
replace them with the notice and other provisions required by the GPL.
If you do not delete the provisions above, a recipient may use your version
of this file under either the MPL or the GPL.

$Id: SynHighlighterAsm.pas,v 1.14.2.6 2008/09/14 16:24:59 maelh Exp $

You may retrieve the latest version of this file at the SynEdit home page,
located at http://SynEdit.SourceForge.net

Known Issues:
-------------------------------------------------------------------------------}
{
@abstract(Provides a x86 Assembler highlighter for SynEdit)
@author(Nick Hoddinott <nickh@conceptdelta.com>, converted to SynEdit by David Muir <david@loanhead45.freeserve.co.uk>)
@created(7 November 1999, converted to SynEdit April 18, 2000)
@lastmod(April 18, 2000)
The SynHighlighterASM unit provides SynEdit with a x86 Assembler (.asm) highlighter.
The highlighter supports all x86 op codes, Intel MMX and AMD 3D NOW! op codes.
Thanks to Martin Waldenburg, Hideo Koiso.
}

{$IFNDEF QSYNHIGHLIGHTERASM}
unit SynHighlighterAsmMASM;
{$ENDIF}

{$I SynEdit.inc}

interface

uses
{$IFDEF SYN_CLX}
  QGraphics,
  QSynEditTypes,
  QSynEditHighlighter,
  QSynHighlighterHashEntries,
  QSynUnicode,
{$ELSE}
  Graphics,
  SynEditTypes,
  SynEditHighlighter,
  SynHighlighterHashEntries,
  SynUnicode,
{$ENDIF}
  SysUtils,
  Classes;

type
  TtkTokenKind = (tkComment, tkIdentifier, tkKey, tkNull, tkNumber, tkSpace,
    tkString, tkSymbol, tkUnknown, tkDirectives, tkRegister, tkApi, tkInclude);

type
  TSynAsmMASMSyn = class(TSynCustomHighlighter)
  private
    fTokenID: TtkTokenKind;
    fCommentAttri: TSynHighlighterAttributes;
    fIncludeAttri: TSynHighlighterAttributes;
    fIdentifierAttri: TSynHighlighterAttributes;
    fKeyAttri: TSynHighlighterAttributes;
    fNumberAttri: TSynHighlighterAttributes;
    fSpaceAttri: TSynHighlighterAttributes;
    fStringAttri: TSynHighlighterAttributes;
    fSymbolAttri: TSynHighlighterAttributes;
    fKeywords: TSynHashEntryList;
    fDirectivesKeywords: TSynHashEntryList;
    fDirectivesAttri: TSynHighlighterAttributes;
    fRegisterKeywords: TSynHashEntryList;
    fRegisterAttri: TSynHighlighterAttributes;
    fApiKeywords: TSynHashEntryList;
    fApiAttri: TSynHighlighterAttributes;
    function HashKey(Str: PWideChar): Cardinal;
    procedure CommentProc;
    procedure CRProc;
    procedure GreaterProc;
    procedure IdentProc;
    procedure LFProc;
    procedure LowerProc;
    procedure NullProc;
    procedure NumberProc;
    procedure SlashProc;
    procedure IncludeProc;
    procedure SpaceProc;
    procedure StringProc;
    procedure SingleQuoteStringProc;
    procedure SymbolProc;
    procedure UnknownProc;
    procedure DoAddKeyword(AKeyword: UnicodeString; AKind: integer);
    procedure DoAddDirectivesKeyword(AKeyword: UnicodeString; AKind: integer);
    procedure DoAddRegisterKeyword(AKeyword: UnicodeString; AKind: integer);
    procedure DoAddApiKeyword(AKeyword: UnicodeString; AKind: integer);
    function IdentKind(MayBe: PWideChar): TtkTokenKind;
  protected
    function GetSampleSource: UnicodeString; override;
    function IsFilterStored: Boolean; override;
  public
    class function GetLanguageName: string; override;
    class function GetFriendlyLanguageName: UnicodeString; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function GetDefaultAttribute(Index: integer): TSynHighlighterAttributes;
      override;
    function GetEol: Boolean; override;
    function GetTokenID: TtkTokenKind;
    function GetTokenAttribute: TSynHighlighterAttributes; override;
    function GetTokenKind: integer; override;
    procedure Next; override;
  published
    property CommentAttri: TSynHighlighterAttributes read fCommentAttri write fCommentAttri;
    property IdentifierAttri: TSynHighlighterAttributes read fIdentifierAttri write fIdentifierAttri;
    property KeyAttri: TSynHighlighterAttributes read fKeyAttri write fKeyAttri;
    property NumberAttri: TSynHighlighterAttributes read fNumberAttri write fNumberAttri;
    property SpaceAttri: TSynHighlighterAttributes read fSpaceAttri write fSpaceAttri;
    property StringAttri: TSynHighlighterAttributes read fStringAttri write fStringAttri;
    property SymbolAttri: TSynHighlighterAttributes read fSymbolAttri write fSymbolAttri;
    property DirectivesAttri: TSynHighlighterAttributes read fDirectivesAttri write fDirectivesAttri;
    property RegisterAttri: TSynHighlighterAttributes read fRegisterAttri write fRegisterAttri;
    property ApiAttri: TSynHighlighterAttributes read fApiAttri write fApiAttri;
    property IncludeAttri: TSynHighlighterAttributes read fIncludeAttri write fIncludeAttri;
  end;

implementation

uses
{$IFDEF SYN_CLX}
  QSynEditStrConst;
{$ELSE}
  SynEditStrConst;
{$ENDIF}

const
  Mnemonics: UnicodeString =
    'aaa,aad,aam,adc,add,and,arpl,bound,bsf,bsr,bswap,bt,btc,' +
    'btr,bts,call,cbw,cdq,clc,cld,cli,clts,cmc,cmp,cmps,cmpsb,cmpsd,cmpsw,' +
    'cmpxchg,cwd,cwde,daa,das,dec,div,emms,enter,f2xm1,fabs,fadd,faddp,fbld,' +
    'fbstp,fchs,fclex,fcmovb,fcmovbe,fcmove,fcmovnb,fcmovnbe,fcmovne,fcmovnu,' +
    'fcmovu,fcom,fcomi,fcomip,fcomp,fcompp,fcos,fdecstp,fdiv,fdivp,fdivr,' +
    'fdivrp,femms,ffree,fiadd,ficom,ficomp,fidiv,fidivr,fild,fimul,fincstp,' +
    'finit,fist,fistp,fisub,fisubr,fld,fld1,fldcw,fldenv,fldl2e,fldl2t,fldlg2,' +
    'fldln2,fldpi,fldz,fmul,fmulp,fnclex,fninit,fnop,fnsave,fnstcw,fnstenv,' +
    'fnstsw,fpatan,fprem1,fptan,frndint,frstor,fsave,fscale,fsin,fsincos,' +
    'fsqrt,fst,fstcw,fstenv,fstp,fstsw,fsub,fsubp,fsubr,fsubrp,ftst,' +
    'fucom,fucomi,fucomip,fucomp,fucompp,fwait,fxch,fxtract,fyl2xp1,hlt,idiv,' +
    'imul,in,inc,ins,insb,insd,insw,int,into,invd,invlpg,iret,iretd,iretw,' +
    'ja,jae,jb,jbe,jc,jcxz,je,jecxz,jg,jge,jl,jle,jmp,jna,jnae,jnb,jnbe,jnc,' +
    'jne,jng,jnge,jnl,jnle,jno,jnp,jns,jnz,jo,jp,jpe,jpo,js,jz,lahf,lar,lds,' +
    'lea,leave,les,lfs,lgdt,lgs,lidt,lldt,lmsw,lock,lods,lodsb,lodsd,lodsw,' +
    'loop,loope,loopne,loopnz,loopz,lsl,lss,ltr,mov,movd,movq, movs,movsb,' +
    'movsd,movsw,movsx,movzx,mul,neg,nop,not,or,out,outs,outsb,outsd,outsw,' +
    'packssdw,packsswb,packuswb,paddb,paddd,paddsb,paddsw,paddusb,paddusw,' +
    'paddw,pand,pandn,pavgusb,pcmpeqb,pcmpeqd,pcmpeqw,pcmpgtb,pcmpgtd,pcmpgtw,' +
    'pf2id,pfacc,pfadd,pfcmpeq,pfcmpge,pfcmpgt,pfmax,pfmin,pfmul,pfrcp,' +
    'pfrcpit1,pfrcpit2,pfrsqit1,pfrsqrt,pfsub,pfsubr,pi2fd,pmaddwd,pmulhrw,' +
    'pmulhw,pmullw,pop,popa,popad,popaw,popf,popfd,popfw,por,prefetch,prefetchw,' +
    'pslld,psllq,psllw,psrad,psraw,psrld,psrlq,psrlw,psubb,psubd,psubsb,' +
    'psubsw,psubusb,psubusw,psubw,punpckhbw,punpckhdq,punpckhwd,punpcklbw,' +
    'punpckldq,punpcklwd,push,pusha,pushad,pushaw,pushf,pushfd,pushfw,pxor,' +
    'rcl,rcr,rep,repe,repne,repnz,repz,ret,rol,ror,sahf,sal,sar,sbb,scas,' +
    'scasb,scasd,scasw,seta,setae,setb,setbe,setc,sete,setg,setge,setl,setle,' +
    'setna,setnae,setnb,setnbe,setnc,setne,setng,setnge,setnl,setnle,setno,' +
    'setnp,setns,setnz,seto,setp,setpo,sets,setz,sgdt,shl,shld,shr,shrd,sidt,' +
    'sldt,smsw,stc,std,sti,stos,stosb,stosd,stosw,str,sub,test,verr,verw,' +
    'wait,wbinvd,xadd,xchg,xlat,xlatb,xor';

  Registers: UnicodeString =
    'ah,al,ax,bh,bl,bx,ch,cl,cs,cx,dh,di,dl,ds,dx,'+
    'eax,ebp,ebx,ecx,edi,edx,es,esi,esp,fs,gs,ip,eip,'+
    'rax,rcx,rdx,rbx,rsp,rbp,rsi,rdisi,ss,'+
    'r0,r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,r11,r12,r13,r14,r15,'+
    'r0D,r1D,r2D,r3D,r4D,r5D,r6D,r7D,r8D,r9D,r10D,r11D,r12D,r13D,r14D,r15D,'+
    'r0W,r1W,r2W,r3W,r4W,r5W,r6W,r7W,r8W,r9W,r10W,r11W,r12W,r13W,r14W,r15W,'+
    'r0L,r1L,r2L,r3L,r4L,r5L,r6L,r7L,r8L,r9L,r10L,r11L,r12L,r13L,r14L,r15L';

  Apis: UnicodeString =
    '__chkstk,__cppvalidateparameters,__glsparser_create,'+
    '__glsparser_print,__glsstring_appendchar,__glsstring_assign,__glsstring_init,'+
    '__pdxgetcmdline,__pdxinitializedata,__validateparameters,__wsafdisset,'+
    '_abnormal_termination,_alldiv,_alldvrm,_allmul,_alloca_probe,_allrem,_allshl,'+
    '_allshr,_aulldiv,_aulldvrm,_aullrem,_aullshr,_bp,_chkstk,_cicos,_cisin,_cisqrt,'+
    '_except_handler2,_except_handler3,_exit,_fptrap,_gcvt,_global_unwind2,_hf2dw,'+
    '_hread,_hwrite,_iob,_ismbcprint,_ismbcspace,_itoa,_itow,_ksedit,_lclose,_lcreat,'+
    '_llseek,_local_unwind2,_lopen,_lread,_ltow,_lwrite,_mbbtombc,_mbctolower,'+
    '_mbschr,_mbscmp,_mbscpy,_mbsdec,_mbsicmp,_mbsinc,_mbslen,_mbslwr,_mbsncmp,'+
    '_mbsncpy,_mbsnextc,_mbsnicmp,_mbsrchr,_mbsstr,_nwlogonqueryadmin,'+
    '_nwlogonsetadmin,_pctype,_purecall,_rt_probe_read4,_security_check_cookie,'+
    '_seh_longjmp_unwind,_setmbcp,_sigjmp_store_mask,_snprintf,_snwprintf,_splitpath,'+
    '_st,_stricmp,_strlwr,_strnicmp,_strnset,_strrev,_strset,_strupr,'+
    '_trackmouseevent,_ultoa,_ultow,_vsnprintf,_vsnwprintf,_wcsicmp,_wcslwr,'+
    '_wcsnicmp,_wcsnset,_wcsrev,_wcsupr,_winstationannoyancepopup,'+
    '_winstationbeepopen,_winstationbreakpoint,_winstationcallback,'+
    '_winstationcheckforapplicationname,_winstationfuscanremoteuserdisconnect,'+
    '_winstationgetapplicationinfo,_winstationnotifydisconnectpipe,'+
    '_winstationnotifylogoff,_winstationnotifylogon,_winstationnotifynewsession,'+
    '_winstationreadregistry,_winstationreinitializesecurity,_winstationshadowtarget,'+
    '_winstationshadowtargetsetup,_winstationupdateclientcachedcredentials,'+
    '_winstationupdatesettings,_winstationupdateuserconfig,_winstationwaitforconnect,'+
    '_wsplitpath,_wtoi,_wtoi64,a_shafinal,a_shainit,a_shaupdate,a2dw,a2wc,abortdoc,'+
    'abortexpert,abortmerges,abortpath,abortprinter,abortsystemshutdown,'+
    'abortsystemshutdowna,abortsystemshutdownw,aboutbox,aboutdlgproc,'+
    'accconvertaccessmasktoactrlaccess,accconvertaccesstosd,'+
    'accconvertaccesstosecuritydescriptor,accconvertacltoaccess,accconvertsdtoaccess,'+
    'accept,acceptex,acceptsecuritycontext,access,accesscheck,'+
    'accesscheckandauditalarm,accesscheckandauditalarma,accesscheckandauditalarmw,'+
    'accesscheckbytype,accesscheckbytypeandauditalarm,'+
    'accesscheckbytypeandauditalarma,accesscheckbytypeandauditalarmw,'+
    'accesscheckbytyperesultlist,accesscheckbytyperesultlistandauditalarm,'+
    'accesscheckbytyperesultlistandauditalarma'+
    'accesscheckbytyperesultlistandauditalarmbyhandle'+
    'accesscheckbytyperesultlistandauditalarmbyhandlea'+
    'accesscheckbytyperesultlistandauditalarmbyhandlew'+
    'accesscheckbytyperesultlistandauditalarmw,accessiblechildren,'+
    'accessibleobjectfromevent,accessibleobjectfrompoint,accessibleobjectfromwindow,'+
    'accessntmslibrarydoor,accgetaccessfortrustee,accgetexplicitentries,'+
    'acclookupaccountname,acclookupaccountsid,acclookupaccounttrustee,'+
    'accprovcanceloperation,accprovgetaccessinfoperobjecttype,accprovgetallrights,'+
    'accprovgetcapabilities,accprovgetoperationresults,accprovgettrusteesaccess,'+
    'accprovgrantaccessrights,accprovhandlegetaccessinfoperobjecttype,'+
    'accprovhandlegetallrights,accprovhandlegettrusteesaccess,'+
    'accprovhandleisaccessaudited,accprovhandleisobjectaccessible,'+
    'accprovhandlerevokeaccessrights,accprovhandlerevokeauditrights,'+
    'accprovhandlesetaccessrights,accprovisaccessaudited,accprovisobjectaccessible,'+
    'accprovrevokeaccessrights,accprovrevokeauditrights,accprovsetaccessrights,'+
    'accsetentriesinalist,acisort,acmdriveradd,acmdriveradda,acmdriveraddw,'+
    'acmdriverclose,acmdriverdetails,acmdriverdetailsa,acmdriverdetailsw,'+
    'acmdriverenum,acmdriverid,acmdrivermessage,acmdriveropen,acmdriverpriority,'+
    'acmdriverremove,acmfilterchoose,acmfilterchoosea,acmfilterchoosew,'+
    'acmfilterdetails,acmfilterdetailsa,acmfilterdetailsw,acmfilterenum,'+
    'acmfilterenuma,acmfilterenumw,acmfiltertagdetails,acmfiltertagdetailsa,'+
    'acmfiltertagdetailsw,acmfiltertagenum,acmfiltertagenuma,acmfiltertagenumw,'+
    'acmformatchoose,acmformatchoosea,acmformatchoosew,acmformatdetails,'+
    'acmformatdetailsa,acmformatdetailsw,acmformatenum,acmformatenuma,acmformatenumw,'+
    'acmformatsuggest,acmformattagdetails,acmformattagdetailsa,acmformattagdetailsw,'+
    'acmformattagenum,acmformattagenuma,acmformattagenumw,acmgetversion,acmmessage32,'+
    'acmmetrics,acmstreamclose,acmstreamconvert,acmstreammessage,acmstreamopen,'+
    'acmstreamprepareheader,acmstreamreset,acmstreamsize,acmstreamunprepareheader,'+
    'acquirecredentialshandle,acquirecredentialshandlea,acquirecredentialshandlew,'+
    'acslan,activateactctx,activatekeyboardlayout,acuiproviderinvokeui,'+
    'addaccessallowedace,addaccessallowedaceex,addaccessallowedobjectace,'+
    'addaccessdeniedace,addaccessdeniedaceex,addaccessdeniedobjectace,addace,'+
    'addaddress,addatom,addatoma,addatomw,addauditaccessace,addauditaccessaceex,'+
    'addauditaccessobjectace,addclusterresourcedependency,addclusterresourcenode,'+
    'addconsolealias,addconsolealiasa,addconsolealiasw,addcredentials,'+
    'addcredentialsa,addcredentialsw,adddelbackupentry,adddesktopitem,'+
    'adddesktopitema,adddesktopitemw,adddrivercatalog,addexperttogroup,'+
    'addfiletofolder,addfoldertocabinet,addfontmemresourceex,addfontresource,'+
    'addfontresourcea,addfontresourceex,addfontresourceexa,addfontresourceexw,'+
    'addfontresourcew,addform,addforma,addformw,addgroup,addipaddress,additem,'+
    'additema,additemw,addjob,addjoba,addjobw,addlocalalternatecomputername,'+
    'addlocalalternatecomputernamea,addlocalalternatecomputernamew,addmonitor,'+
    'addmonitora,addmonitorw,addmrustring,addmrustringw,addntmsmediatype,'+
    'addpermachineconnection,addpermachineconnectiona,addpermachineconnectionw,'+
    'addpersonaltrustdbpages,addport,addporta,addportex,addportexa,addportexw,'+
    'addportw,addprinter,addprintera,addprinterconnection,addprinterconnectiona,'+
    'addprinterconnectionw,addprinterdriver,addprinterdrivera,addprinterdriverex,'+
    'addprinterdriverexa,addprinterdriverexw,addprinterdriverw,addprinterex,'+
    'addprinterexw,addprinterw,addprintprocessor,addprintprocessora,'+
    'addprintprocessorw,addprintprovidor,addprintprovidora,addprintprovidorw,'+
    'addproperty,addrefactctx,addresstostring,addresstypetomactype,addrvect,'+
    'addsecuritypackage,addsecuritypackagea,addsecuritypackagew,'+
    'adduserstoencryptedfile,addvectoredexceptionhandler,adjmsg,'+
    'adjustoperatorprecedence,adjustpacketbuffer,adjustpointers,'+
    'adjustpointersinstructuresarray,adjustsystemtime,adjusttokengroups,'+
    'adjusttokenprivileges,adjustwindowrect,adjustwindowrectex,adsbuildenumerator,'+
    'adsbuildvararrayint,adsbuildvararraystr,adsdecodebinarydata,adsencodebinarydata,'+
    'adsenumeratenext,adsfreeadsvalues,adsfreeenumerator,adsgetlasterror,'+
    'adsgetobject,adsopenobject,adspropcheckifwritable,adspropcreatenotifyobj,'+
    'adspropgetinitinfo,adspropsenderrormessage,adspropsethwnd,'+
    'adspropsethwndwithtitle,adspropshowerrordialog,adssetlasterror,'+
    'adstypetopropvariant,adstypetopropvariant2,advanceddocumentproperties,'+
    'advanceddocumentpropertiesa,advanceddocumentpropertiesw,advancedsetupdialog,'+
    'advinstallfile,aissort,alarm,alignkmptr,alignrpcptr,alloc,allocadsmem,'+
    'allocadsstr,allocate_decompression_memory,allocateandgetarpenttablefromstack,'+
    'allocateandgetiftablefromstack,allocateandgetipaddrtablefromstack,'+
    'allocateandgetipforwardtablefromstack,allocateandgetipnettablefromstack,'+
    'allocateandgettcpextable2fromstack,allocateandgettcpextablefromstack,'+
    'allocateandgettcptablefromstack,allocateandgetudpextable2fromstack,'+
    'allocateandgetudpextablefromstack,allocateandgetudptablefromstack,'+
    'allocateandinitializesid,allocateattributes,allocatelocallyuniqueid,'+
    'allocatentmsmedia,allocateuserphysicalpages,allocb,alloccachedumpstatstohtml,'+
    'allocconsole,allocmemory,allocnetworkbuffer,allocobject,allocsplstr,'+
    'allowsetforegroundwindow,alphablend,amgeterrortext,amgeterrortexta,'+
    'amgeterrortextw,ampfactortodb,andexpression,anglearc,animatepalette,'+
    'animatewindow,anypopup,apidllentry,appcleanup,appendmenu,appendmenua,'+
    'appendmenuw,appendprinternotifyinfodata,appendrdn,applycontroltoken,'+
    'applygrouppolicy,applysystempolicy,applysystempolicya,applysystempolicyw,arc,'+
    'arcfilterdprindicatereceive,arcfilterdprindicatereceivecomplete,arcto,'+
    'areallaccessesgranted,areanyaccessesgranted,arefileapisansi,argbynumber,argcl,'+
    'argclc,arith_close,arith_decode_bits,arith_init,arr_add,arr_mul,arr_sub,'+
    'arr2file,arr2mem,arr2text,arralloc,arrangeiconicwindows,arrbin,arrcnt,arrealloc,'+
    'arrextnd,arrfile,arrfree,arrget,arrlen,arrset,arrtotal,arrtrunc,arrtxt,'+
    'asciidump,asn1_closedecoder,asn1_closeencoder,asn1_closeencoder2,'+
    'asn1_closemodule,asn1_createdecoder,asn1_createdecoderex,asn1_createencoder,'+
    'asn1_createmodule,asn1_decode,asn1_encode,asn1_freedecoded,asn1_freeencoded,'+
    'asn1_getdecoderoption,asn1_getencoderoption,asn1_setdecoderoption,'+
    'asn1_setencoderoption,asn1berdecbitstring,asn1berdecbitstring2,asn1berdecbool,'+
    'asn1berdecchar16string,asn1berdecchar32string,asn1berdeccharstring,'+
    'asn1berdeccheck,asn1berdecdouble,asn1berdecendofcontents,asn1berdeceoid,'+
    'asn1berdecexplicittag,asn1berdecflush,asn1berdecgeneralizedtime,'+
    'asn1berdeclength,asn1berdecmultibytestring,asn1berdecnotendofcontents,'+
    'asn1berdecnull,asn1berdecobjectidentifier,asn1berdecobjectidentifier2,'+
    'asn1berdecoctetstring,asn1berdecoctetstring2,asn1berdecopentype,'+
    'asn1berdecopentype2,asn1berdecpeektag,asn1berdecs16val,asn1berdecs32val,'+
    'asn1berdecs8val,asn1berdecskip,asn1berdecsxval,asn1berdectag,asn1berdecu16val,'+
    'asn1berdecu32val,asn1berdecu8val,asn1berdecutctime,asn1berdecutf8string,'+
    'asn1berdeczerochar16string,asn1berdeczerochar32string,asn1berdeczerocharstring,'+
    'asn1berdeczeromultibytestring,asn1berdotval2eoid,asn1berencbitstring,'+
    'asn1berencbool,asn1berencchar16string,asn1berencchar32string,'+
    'asn1berenccharstring,asn1berenccheck,asn1berencdouble,asn1berencendofcontents,'+
    'asn1berenceoid,asn1berencexplicittag,asn1berencflush,asn1berencgeneralizedtime,'+
    'asn1berenclength,asn1berencmultibytestring,asn1berencnull,'+
    'asn1berencobjectidentifier,asn1berencobjectidentifier2,asn1berencoctetstring,'+
    'asn1berencopentype,asn1berencremovezerobits,asn1berencs32,asn1berencsx,'+
    'asn1berenctag,asn1berencu32,asn1berencutctime,asn1berencutf8string,'+
    'asn1berenczeromultibytestring,asn1bereoid_free,asn1bereoid2dotval,'+
    'asn1bitstring_cmp,asn1bitstring_free,asn1cerencbeginblk,asn1cerencbitstring,'+
    'asn1cerencchar16string,asn1cerencchar32string,asn1cerenccharstring,'+
    'asn1cerencendblk,asn1cerencflushblkelement,asn1cerencgeneralizedtime,'+
    'asn1cerencmultibytestring,asn1cerencnewblkelement,asn1cerencoctetstring,'+
    'asn1cerencutctime,asn1cerenczeromultibytestring,asn1char16string_cmp,'+
    'asn1char16string_free,asn1char32string_cmp,asn1char32string_free,'+
    'asn1charstring_cmp,asn1charstring_free,asn1decabort,asn1decalloc,asn1decdone,'+
    'asn1decrealloc,asn1decseterror,asn1encabort,asn1encdone,asn1encseterror,'+
    'asn1free,asn1generalizedtime_cmp,asn1intx_add,asn1intx_free,asn1intx_setuint32,'+
    'asn1intx_sub,asn1intx_uoctets,asn1intx2int32,asn1intx2uint32,asn1intxisuint32,'+
    'asn1objectidentifier_cmp,asn1objectidentifier_free,asn1objectidentifier2_cmp,'+
    'asn1octetstring_cmp,asn1octetstring_free,asn1open_cmp,asn1open_free,'+
    'asn1perdecalignment,asn1perdecbit,asn1perdecbits,asn1perdecboolean,'+
    'asn1perdecchar16string,asn1perdecchar32string,asn1perdeccharstring,'+
    'asn1perdeccharstringnoalloc,asn1perdeccomplexchoice,asn1perdecdouble,'+
    'asn1perdecextension,asn1perdecflush,asn1perdecfragmented,'+
    'asn1perdecfragmentedchar16string,asn1perdecfragmentedchar32string,'+
    'asn1perdecfragmentedcharstring,asn1perdecfragmentedextension,'+
    'asn1perdecfragmentedintx,asn1perdecfragmentedlength,'+
    'asn1perdecfragmentedtablechar16string,asn1perdecfragmentedtablechar32string,'+
    'asn1perdecfragmentedtablecharstring,asn1perdecfragmenteduintx,'+
    'asn1perdecfragmentedzerochar16string,asn1perdecfragmentedzerochar32string,'+
    'asn1perdecfragmentedzerocharstring,asn1perdecfragmentedzerotablechar16string,'+
    'asn1perdecfragmentedzerotablechar32string'+
    'asn1perdecfragmentedzerotablecharstring,asn1perdecgeneralizedtime,'+
    'asn1perdecinteger,asn1perdecmultibytestring,asn1perdecn16val,asn1perdecn32val,'+
    'asn1perdecn8val,asn1perdecnormallysmallextension,asn1perdecobjectidentifier,'+
    'asn1perdecobjectidentifier2,asn1perdecoctetstring_fixedsize,'+
    'asn1perdecoctetstring_fixedsizeex,asn1perdecoctetstring_nosize,'+
    'asn1perdecoctetstring_varsize,asn1perdecoctetstring_varsizeex,asn1perdecs16val,'+
    'asn1perdecs32val,asn1perdecs8val,asn1perdecseqof_nosize,asn1perdecseqof_varsize,'+
    'asn1perdecsimplechoice,asn1perdecsimplechoiceex,asn1perdecskipbits,'+
    'asn1perdecskipfragmented,asn1perdecskipnormallysmall,'+
    'asn1perdecskipnormallysmallextension'+
    'asn1perdecskipnormallysmallextensionfragmented,asn1perdecsxval,'+
    'asn1perdectablechar16string,asn1perdectablechar32string,'+
    'asn1perdectablecharstring,asn1perdectablecharstringnoalloc,asn1perdecu16val,'+
    'asn1perdecu32val,asn1perdecu8val,asn1perdecunsignedinteger,'+
    'asn1perdecunsignedshort,asn1perdecutctime,asn1perdecuxval,'+
    'asn1perdeczerochar16string,asn1perdeczerochar32string,asn1perdeczerocharstring,'+
    'asn1perdeczerocharstringnoalloc,asn1perdeczerotablechar16string,'+
    'asn1perdeczerotablechar32string,asn1perdeczerotablecharstring,'+
    'asn1perdeczerotablecharstringnoalloc,asn1perencalignment,asn1perencbit,'+
    'asn1perencbitintx,asn1perencbits,asn1perencbitval,asn1perencboolean,'+
    'asn1perencchar16string,asn1perencchar32string,asn1perenccharstring,'+
    'asn1perenccheckextensions,asn1perenccomplexchoice,asn1perencdouble,'+
    'asn1perencextensionbitclear,asn1perencextensionbitset,asn1perencflush,'+
    'asn1perencflushfragmentedtoparent,asn1perencfragmented,'+
    'asn1perencfragmentedchar16string,asn1perencfragmentedchar32string,'+
    'asn1perencfragmentedcharstring,asn1perencfragmentedintx,'+
    'asn1perencfragmentedlength,asn1perencfragmentedtablechar16string,'+
    'asn1perencfragmentedtablechar32string,asn1perencfragmentedtablecharstring,'+
    'asn1perencfragmenteduintx,asn1perencgeneralizedtime,asn1perencinteger,'+
    'asn1perencmultibytestring,asn1perencnormallysmall,asn1perencnormallysmallbits,'+
    'asn1perencobjectidentifier,asn1perencobjectidentifier2,asn1perencoctets,'+
    'asn1perencoctetstring_fixedsize,asn1perencoctetstring_fixedsizeex,'+
    'asn1perencoctetstring_nosize,asn1perencoctetstring_varsize,'+
    'asn1perencoctetstring_varsizeex,asn1perencremovezerobits,asn1perencseqof_nosize,'+
    'asn1perencseqof_varsize,asn1perencsimplechoice,asn1perencsimplechoiceex,'+
    'asn1perenctablechar16string,asn1perenctablechar32string,'+
    'asn1perenctablecharstring,asn1perencunsignedinteger,asn1perencunsignedshort,'+
    'asn1perencutctime,asn1perenczero,asn1perfreeseqof,asn1uint32_uoctets,'+
    'asn1utctime_cmp,asn1utf8string_free,asn1ztchar16string_cmp,'+
    'asn1ztchar16string_free,asn1ztchar32string_free,asn1ztcharstring_cmp,'+
    'asn1ztcharstring_free,asqsort,asraddsifentry,asraddsifentrya,asraddsifentryw,'+
    'asrcreatestatefile,asrcreatestatefilea,asrcreatestatefilew,asrfreecontext,'+
    'asrpgetlocaldiskinfo,asrpgetlocalvolumeinfo,asrprestorenoncriticaldisks,'+
    'asrprestorenoncriticaldisksw,asrrestoreplugplayregistrydata,'+
    'assignprocesstojobobject,assoccreate,assocgetperceivedtype,'+
    'associatecolorprofilewithdevice,associatecolorprofilewithdevicea,'+
    'associatecolorprofilewithdevicew,associsdangerous,assocquerykey,assocquerykeya,'+
    'assocquerykeyw,assocquerystring,assocquerystringa,assocquerystringbykey,'+
    'assocquerystringbykeya,assocquerystringbykeyw,assocquerystringw,assoctable,'+
    'assort,asyncdcom,asyncmsg,asyncrpc,atlcomptrassign,atlinternalqueryinterface,'+
    'atodw,atodw_ex,atoi,atol,atqaddasynchandle,atqbandwidthgetinfo,'+
    'atqbandwidthsetinfo,atqclearstatistics,atqcloseendpoint,atqclosefilehandle,'+
    'atqclosesocket,atqcontextgetinfo,atqcontextsetinfo,atqcontextsetinfo2,'+
    'atqcreatebandwidthinfo,atqcreateendpoint,atqendpointgetinfo,atqendpointsetinfo,'+
    'atqendpointsetinfo2,atqfreebandwidthinfo,atqfreecontext,atqgetacceptexaddrs,'+
    'atqgetdatagramaddrs,atqgetinfo,atqgetstatistics,atqinitialize,'+
    'atqpostcompletionstatus,atqreaddirchanges,atqreadfile,atqreadsocket,atqsetinfo,'+
    'atqsetinfo2,atqspudinitialized,atqstartendpoint,atqstopandcloseendpoint,'+
    'atqstopendpoint,atqsyncwsasend,atqterminate,atqtransmitfile,'+
    'atqwritedatagramsocket,atqwritefile,atqwritesocket,attachconsole,'+
    'attachpropertyinstance,attachpropertyinstanceex,attachthreadinput,attrtypetokey,'+
    'authinfo,authzaccesscheck,authzaddsidstocontext,authzcachedaccesscheck,'+
    'authzfreeauditevent,authzfreecontext,authzfreehandle,authzfreeresourcemanager,'+
    'authzgetinformationfromcontext,authzilogauditevent,'+
    'authzinitializecontextfromauthzcontext,authzinitializecontextfromsid,'+
    'authzinitializecontextfromtoken,authzinitializeobjectaccessauditevent,'+
    'authzinitializeresourcemanager,authzopenobjectaudit,aux32message,auxgetdevcaps,'+
    'auxgetdevcapsa,auxgetdevcapsw,auxgetnumdevs,auxgetvolume,auxoutmessage,'+
    'auxsetvolume,avibuildfilter,avibuildfiltera,avibuildfilterw,aviclearclipboard,'+
    'avifileaddref,avifilecreatestream,avifilecreatestreama,avifilecreatestreamw,'+
    'avifileendrecord,avifileexit,avifilegetstream,avifileinfo,avifileinfoa,'+
    'avifileinfow,avifileinit,avifileopen,avifileopena,avifileopenw,avifilereaddata,'+
    'avifilerelease,avifilewritedata,avigetfromclipboard,avimakecompressedstream,'+
    'avimakefilefromstreams,avimakestreamfromclipboard,aviputfileonclipboard,avisave,'+
    'avisavea,avisaveoptions,avisaveoptionsfree,avisavev,avisaveva,avisavevw,'+
    'avisavew,avistreamaddref,avistreambeginstreaming,avistreamcreate,'+
    'avistreamendstreaming,avistreamfindsample,avistreamgetframe,'+
    'avistreamgetframeclose,avistreamgetframeopen,avistreaminfo,avistreaminfoa,'+
    'avistreaminfow,avistreamlength,avistreamopenfromfile,avistreamopenfromfilea,'+
    'avistreamopenfromfilew,avistreamread,avistreamreaddata,avistreamreadformat,'+
    'avistreamrelease,avistreamsampletotime,avistreamsetformat,avistreamstart,'+
    'avistreamtimetosample,avistreamwrite,avistreamwritedata,b,backq,'+
    'backupclusterdatabase,backupeventlog,backupeventloga,backupeventlogw,'+
    'backupperfregistrytofile,backupperfregistrytofilew,backupread,backupseek,'+
    'backupwrite,basecheckappcompatcache,basecleanupappcompatcache,'+
    'basecleanupappcompatcachesupport,basedumpappcompatcache,baseflushappcompatcache,'+
    'baseinitappcompatcache,baseinitappcompatcachesupport,'+
    'basepcheckwinsaferrestrictions,baseprocessinitpostimport,basequerymoduledata,'+
    'basesetprocesscreatenotify,basesrvnewobdiracls,basesrvnlslogon,'+
    'basesrvnlsupdateregistrycache,baseupdateappcompatcache,batmetercapabilities,'+
    'batteryclassinitializedevice,batteryclassioctl,batteryclassquerywmidatablock,'+
    'batteryclassstatusnotify,batteryclasssystemcontrol,batteryclassunload,bcache,'+
    'bdacheckchanges,bdacommitchanges,bdacreatefilterfactory,'+
    'bdacreatefilterfactoryex,bdacreatepin,bdacreatetopology,bdadeletepin,'+
    'bdafilterfactoryupdatecachedata,bdagetchangestate,bdainitfilter,'+
    'bdamethodcreatepin,bdamethodcreatetopology,bdamethoddeletepin,'+
    'bdapropertygetcontrollingpinid,bdapropertygetpincontrol,'+
    'bdapropertynodedescriptors,bdapropertynodeevents,bdapropertynodemethods,'+
    'bdapropertynodeproperties,bdapropertynodetypes,bdapropertypintypes,'+
    'bdapropertytemplateconnections,bdastartchanges,bdauninitfilter,'+
    'bdavalidatenodeproperty,beep,begincachetransaction,begindeferwindowpos,'+
    'beginntmsdevicechangedetection,beginpaint,beginpath,beginupdateresource,'+
    'beginupdateresourcea,beginupdateresourcew,ber_alloc_t,ber_bvdup,ber_bvecfree,'+
    'ber_bvfree,ber_first_element,ber_flatten,ber_free,ber_init,ber_next_element,'+
    'ber_peek_tag,ber_printf,ber_scanf,ber_skip_tag,bergetheader,bergetinteger,'+
    'bergetstring,bestmatchintable,bgetdevmodeperuser,bhallocsystemmemory,'+
    'bhfreesystemmemory,bhgetlasterror,bhgetwindowsversion,bhglobaltimer,bhkilltimer,'+
    'bhsetlasterror,bhsettimer,bi_init,bi_reverse,bi_windup,bin2byte_ex,bin2hex,'+
    'binary_search_findmatch,binary_search_remove_node,binarysdtosecuritydescriptor,'+
    'bind,bindasyncmoniker,bindifilterfromstorage,bindifilterfromstream,bindimage,'+
    'bindimageex,bindiocompletioncallback,bindmoniker,binsearch,binsert,bitblt,'+
    'bitmapfromfile,bitmapfrommemory,bitmapfrompicture,bitmapfromresource,block_end,'+
    'blockinput,blockwowidle,bltccwndproc,bltdlgproc,bltwndproc,bmbinsearch,'+
    'bmchangedata,bmclone,bmcopy,bmdraw,bmenumformat,bmequal,bmgetdata,bmhbinsearch,'+
    'bmpbutton,bmquerybounds,bmrelease,bmsavetostream,breakconnections,'+
    'breakrecordsintoblob,bringsheettoforeground,bringwindowtotop,'+
    'broadcastsystemmessage,broadcastsystemmessagea,broadcastsystemmessageex,'+
    'broadcastsystemmessageexa,broadcastsystemmessageexw,broadcastsystemmessagew,'+
    'browseforfolder,browseforgpo,browseinfo,brushobj_hgetcolortransform,'+
    'brushobj_pvallocrbrush,brushobj_pvgetrbrush,brushobj_ulgetbrushcolor,'+
    'bsetdevmodeperuser,bstr_userfree,bstr_usermarshal,bstr_usersize,'+
    'bstr_userunmarshal,bstrfromvector,bstsorta,bstsortd,bufcall,build_bl_tree,'+
    'build_tree,buildcommdcb,buildcommdcba,buildcommdcbandtimeouts,'+
    'buildcommdcbandtimeoutsa,buildcommdcbandtimeoutsw,buildcommdcbw,'+
    'builddisplaytable,buildexplicitaccesswithname,buildexplicitaccesswithnamea,'+
    'buildexplicitaccesswithnamew,buildimpersonateexplicitaccesswithname,'+
    'buildimpersonateexplicitaccesswithnamea,buildimpersonateexplicitaccesswithnamew,'+
    'buildimpersonatetrustee,buildimpersonatetrusteea,buildimpersonatetrusteew,'+
    'buildinipath,buildothernamesfrommachinename,buildsecuritydescriptor,'+
    'buildsecuritydescriptora,buildsecuritydescriptorw,buildtrusteewithname,'+
    'buildtrusteewithnamea,buildtrusteewithnamew,buildtrusteewithobjectsandname,'+
    'buildtrusteewithobjectsandnamea,buildtrusteewithobjectsandnamew,'+
    'buildtrusteewithobjectsandsid,buildtrusteewithobjectsandsida,'+
    'buildtrusteewithobjectsandsidw,buildtrusteewithsid,buildtrusteewithsida,'+
    'buildtrusteewithsidw,bus1394registerportdriver,byt2bin_ex,byte_count,'+
    'byte_flag_to_string,bytetobinary,cabdestroy,'+
    'call_ica_hw_interrupt,callback,callback12,callback16,'+
    'callback20,callback24,callback28,callback32,callback36,callback4,callback40,'+
    'callback44,callback48,callback52,callback56,callback60,callback64,callback8,'+
    'callcommonpropertysheetui,callcplentry16,calldrvdevmodeconversion,callmsgfilter,'+
    'callmsgfiltera,callmsgfilterw,callnamedpipe,callnamedpipea,callnamedpipew,'+
    'callnexthookex,callntpowerinformation,'+
    'callrouterfindfirstprinterchangenotification,callwindowproc,callwindowproca,'+
    'callwindowprocw,canceldc,canceldevicewakeuprequest,cancelio,'+
    'cancelipchangenotify,cancelntmslibraryrequest,cancelntmsoperatorrequest,'+
    'canceloverlappedaccess,canceltimerqueuetimer,canceltransmit,cancelwaitabletimer,'+
    'canonhex,canonicalizehexstring,canput,canputnext,canresourcebedependent,'+
    'canuserwritepwrscheme,capcreatecapturewindow,capcreatecapturewindowa,'+
    'capcreatecapturewindoww,capgetdriverdescription,capgetdriverdescriptiona,'+
    'capgetdriverdescriptionw,cascadechildwindows,cascadewindows,'+
    'catalogcompacthashdatabase,cbgszlen,cbofencoded,cbvszlen,cccaniwrite,cccopyread,'+
    'cccopywrite,ccdeferwrite,ccfastcopyread,ccfastcopywrite,ccfastmdlreadwait,'+
    'ccfastreadnotpossible,ccfastreadwait,ccfcertificateenterui,'+
    'ccfcertificateremoveui,ccflushcache,ccgetdirtypages,ccgetfileobjectfrombcb,'+
    'ccgetfileobjectfromsectionptrs,ccgetflushedvaliddata,ccgetlsnforfileobject,'+
    'ccheapalloc,ccheapfree,ccheaprealloc,ccheapsize,cchgszlen,cchofencoding,'+
    'cchvszlen,ccinitializecachemap,ccistheredirtydata,ccmapdata,ccmdlread,'+
    'ccmdlreadcomplete,ccmdlwriteabort,ccmdlwritecomplete,ccpinmappeddata,ccpinread,'+
    'ccpreparemdlwrite,ccpreparepinwrite,ccpurgecachesection,ccremapbcb,ccrepinbcb,'+
    'ccschedulereadahead,ccsetadditionalcacheattributes,ccsetbcbownerpointer,'+
    'ccsetdirtypagethreshold,ccsetdirtypinneddata,ccsetfilesizes,'+
    'ccsetloghandleforfile,ccsetreadaheadgranularity,ccsorta,ccsortd,'+
    'ccuninitializecachemap,ccunpindata,ccunpindataforthread,ccunpinrepinnedbcb,'+
    'ccwaitforcurrentlazywriteractivity,cczerodata,cdbuildintegrityvect,cdbuildvect,'+
    'cdeffoldermenu_create,cdeffoldermenu_create2,cdfindcommoncsystem,'+
    'cdfindcommoncsystemwithkey,cdgeneraterandombits,cdlocatechecksum,'+
    'cdlocatecsystem,cdlocaterng,cdregisterchecksum,cdregistercsystem,cdregisterrng,'+
    'cdromproppageprovider,certaddcertificatecontexttostore,'+
    'certaddcertificatelinktostore,certaddcrlcontexttostore,certaddcrllinktostore,'+
    'certaddctlcontexttostore,certaddctllinktostore,certaddencodedcertificatetostore,'+
    'certaddencodedcertificatetosystemstore,certaddencodedcertificatetosystemstorea,'+
    'certaddencodedcertificatetosystemstorew,certaddencodedcrltostore,'+
    'certaddencodedctltostore,certaddenhancedkeyusageidentifier,'+
    'certaddserializedelementtostore,certaddstoretocollection,certalgidtooid,'+
    'certclosestore,certcomparecertificate,certcomparecertificatename,'+
    'certcompareintegerblob,certcomparepublickeyinfo,certcontrolstore,'+
    'certcreatecertificatechainengine,certcreatecertificatecontext,certcreatecontext,'+
    'certcreatecrlcontext,certcreatectlcontext,'+
    'certcreatectlentryfromcertificatecontextproperties,certcreateselfsigncertificate,'+
    'certdeletecertificatefromstore,certdeletecrlfromstore,certdeletectlfromstore,'+
    'certduplicatecertificatechain,certduplicatecertificatecontext,'+
    'certduplicatecrlcontext,certduplicatectlcontext,certduplicatestore,'+
    'certenumcertificatecontextproperties,certenumcertificatesinstore,'+
    'certenumcrlcontextproperties,certenumcrlsinstore,certenumctlcontextproperties,'+
    'certenumctlsinstore,certenumphysicalstore,certenumsubjectinsortedctl,'+
    'certenumsystemstore,certenumsystemstorelocation,certfindattribute,'+
    'certfindcertificateincrl,certfindcertificateinstore,certfindchaininstore,'+
    'certfindcrlinstore,certfindctlinstore,certfindextension,certfindrdnattr,'+
    'certfindsubjectinctl,certfindsubjectinsortedctl,certfreecertificatechain,'+
    'certfreecertificatechainengine,certfreecertificatecontext,certfreecrlcontext,'+
    'certfreectlcontext,certgetcertificatechain,certgetcertificatecontextproperty,'+
    'certgetcrlcontextproperty,certgetcrlfromstore,certgetctlcontextproperty,'+
    'certgetenhancedkeyusage,certgetintendedkeyusage,'+
    'certgetissuercertificatefromstore,certgetnamestring,certgetnamestringa,'+
    'certgetnamestringw,certgetpublickeylength,certgetstoreproperty,'+
    'certgetsubjectcertificatefromstore,certgetvalidusages,'+
    'certisrdnattrsincertificatename,certisvalidcrlforcertificate,certnametostr,'+
    'certnametostra,certnametostrw,certoidtoalgid,certopenstore,certopensystemstore,'+
    'certopensystemstorea,certopensystemstorew,certrdnvaluetostr,certrdnvaluetostra,'+
    'certrdnvaluetostrw,certregisterphysicalstore,certregistersystemstore,'+
    'certremoveenhancedkeyusageidentifier,certremovestorefromcollection,'+
    'certresynccertificatechainengine,certsavestore,'+
    'certserializecertificatestoreelement,certserializecrlstoreelement,'+
    'certserializectlstoreelement,certserverrequest,'+
    'certsetcertificatecontextpropertiesfromctlentry'+
    'certsetcertificatecontextproperty,certsetcrlcontextproperty,'+
    'certsetctlcontextproperty,certsetenhancedkeyusage,certsetstoreproperty,'+
    'certsrvbackupclose,certsrvbackupend,certsrvbackupfree,'+
    'certsrvbackupgetbackuplogs,certsrvbackupgetbackuplogsw,'+
    'certsrvbackupgetdatabasenames,certsrvbackupgetdatabasenamesw,'+
    'certsrvbackupgetdynamicfilelist,certsrvbackupgetdynamicfilelistw,'+
    'certsrvbackupopenfile,certsrvbackupopenfilew,certsrvbackupprepare,'+
    'certsrvbackuppreparew,certsrvbackupread,certsrvbackuptruncatelogs,'+
    'certsrvisserveronline,certsrvisserveronlinew,certsrvrestoreend,'+
    'certsrvrestoregetdatabaselocations,certsrvrestoregetdatabaselocationsw,'+
    'certsrvrestoreprepare,certsrvrestorepreparew,certsrvrestoreregister,'+
    'certsrvrestoreregistercomplete,certsrvrestoreregisterthroughfile,'+
    'certsrvrestoreregisterw,certsrvservercontrol,certsrvservercontrolw,'+
    'certstrtoname,certstrtonamea,certstrtonamew,certunregisterphysicalstore,'+
    'certunregistersystemstore,certverifycertificatechainpolicy,'+
    'certverifycrlrevocation,certverifycrltimevalidity,certverifyctlusage,'+
    'certverifyrevocation,certverifysubjectcertificatecontext,certverifytimevalidity,'+
    'certverifyvaliditynesting,cfgetispeed,cfgetospeed,cfsetispeed,cfsetospeed,'+
    'changeclipboardchain,changeclusterresourcegroup,changedisplaysettings,'+
    'changedisplaysettingsa,changedisplaysettingsex,changedisplaysettingsexa,'+
    'changedisplaysettingsexw,changedisplaysettingsw,changeidleroutine,changemenu,'+
    'changemenua,changemenuw,changentmsmediatype,changerclassallocatepool,'+
    'changerclassdebugprint,changerclassfreepool,changerclassinitialize,'+
    'changerclasssendsrbsynchronous,changeserviceconfig,changeserviceconfig2,'+
    'changeserviceconfig2a,changeserviceconfig2w,changeserviceconfiga,'+
    'changeserviceconfigw,changesupervisorpassword,changetimerqueuetimer,charformat2,'+
    'charlower,charlowera,charlowerbuff,charlowerbuffa,charlowerbuffw,charlowerw,'+
    'charnext,charnexta,charnextexa,charnextw,charprev,charpreva,charprevexa,'+
    'charprevw,chartooem,chartooema,chartooembuff,chartooembuffa,chartooembuffw,'+
    'chartooemw,charupper,charuppera,charupperbuff,charupperbuffa,charupperbuffw,'+
    'charupperw,chdir,checkaccessforpolicygeneration,checkbitmapbits,checkcolors,'+
    'checkcolorsingamut,checkcsc,checkcscex,checkdlgbutton,checkdspolicy,'+
    'checkescapes,checkescapesa,checkescapesw,checkforversionconflict,checkmenuitem,'+
    'checkmenuradioitem,checknamelegaldos8dot3,checknamelegaldos8dot3a,'+
    'checknamelegaldos8dot3w,checknetdrive,checkradiobutton,'+
    'checkremotedebuggerpresent,checkrpcsym,checksummappedfile,checktable,'+
    'checktokenmembership,checktrust,checktrustex,checkverificationtrailer,'+
    'checkxforestlogon,childwindowfrompoint,childwindowfrompointex,chmod,choosecolor,'+
    'choosecolora,choosecolorw,choosedlgproc,choosefont,choosefonta,choosefontw,'+
    'choosepixelformat,chord,chown,chrcmpi,chrcmpia,chrcmpiw,cibuildquerynode,'+
    'cibuildquerytree,cicreatecommand,cigetglobalpropertylist,cimakeicommand,circle,'+
    'cirestrictiontofulltree,cistate,cisvcmain,citexttofulltree,citexttofulltreeex,'+
    'citexttoselecttree,citexttoselecttreeex,classacquirechildlock,'+
    'classacquireremovelockex,classasynchronouscompletion,classbuildrequest,'+
    'classcheckmediastate,classclaimdevice,classcleanupmediachangedetection,'+
    'classcompleterequest,classcreatedeviceobject,classdebugprint,'+
    'classdeletesrblookasidelist,classdevicecontrol,classdisablemediachangedetection,'+
    'classenablemediachangedetection,classfindmodepage,classforwardirpsynchronous,'+
    'classgetdescriptor,classgetdeviceparameter,classgetdriverextension,classgetvpb,'+
    'classinitialize,classinitializeex,classinitializemediachangedetection,'+
    'classinitializesrblookasidelist,classinitializetestunitpolling,'+
    'classinternaliocontrol,classinterpretsenseinfo,classinvalidatebusrelations,'+
    'classiocomplete,classiocompleteassociated,classmarkchildmissing,'+
    'classmarkchildrenmissing,classmodesense,classnotifyfailurepredicted,'+
    'classquerytimeoutregistryvalue,classreaddrivecapacity,classreleasechildlock,'+
    'classreleasequeue,classreleaseremovelock,classremovedevice,'+
    'classresetmediachangetimer,classscanforspecial,'+
    'classsenddeviceiocontrolsynchronous,classsendirpsynchronous,'+
    'classsendsrbasynchronous,classsendsrbsynchronous,classsendstartunit,'+
    'classsetdeviceparameter,classsetfailurepredictionpoll,classsetmediachangestate,'+
    'classsignalcompletion,classspindownpowerhandler,classsplitrequest,'+
    'classstopunitpowerhandler,classupdateinformationinregistry,'+
    'classwmicompleterequest,classwmifireevent,cldap_open,cldap_opena,cldap_openw,'+
    'cleanntmsdrive,cleanupcache,clearcommbreak,clearcommerror,clearcustdata,'+
    'cleardisplaytext,cleareventdata,cleareventlog,cleareventloga,cleareventlogw,'+
    'clearstatistics,clickedonprf,clickedonrat,clientsideinstall,clientsideinstallw,'+
    'clienttoscreen,clipcursor,clipformat_userfree,clipformat_usermarshal,'+
    'clipformat_usersize,clipformat_userunmarshal,clipobj_benum,clipobj_cenumstart,'+
    'clipobj_ppogetpath,close,closeclipboard,closecluster,closeclustergroup,'+
    'closeclusternetinterface,closeclusternetwork,closeclusternode,'+
    'closeclusternotifyport,closeclusterresource,closecodeauthzlevel,'+
    'closecolorprofile,closeconsolehandle,closedesktop,closedir,'+
    'closednsperformancedata,closedriver,closeencryptedfileraw,closeenhmetafile,'+
    'closeeventlog,closefigure,closehandle,closeimsgsession,closeinfengine,'+
    'closemetafile,closemmf,closencpsrvperformancedata,closenetwork,'+
    'closentmsnotification,closentmssession,closeodbcperfdata,closeport,closeprinter,'+
    'closeprintprocessor,closeprofileusermapping,closeservicehandle,closesocket,'+
    'closespoolfilehandle,closesslperformancedata,closethemedata,closetrace,'+
    'closeuserbrowser,closewindow,closewindowstation,clsidfromprogid,'+
    'clsidfromprogidex,clsidfromstring,clustercloseenum,clustercontrol,clusterenum,'+
    'clustergetenumcount,clustergroupcloseenum,clustergroupcontrol,clustergroupenum,'+
    'clustergroupgetenumcount,clustergroupopenenum,clusternetinterfacecontrol,'+
    'clusternetworkcloseenum,clusternetworkcontrol,clusternetworkenum,'+
    'clusternetworkgetenumcount,clusternetworkopenenum,clusternodecloseenum,'+
    'clusternodecontrol,clusternodeenum,clusternodegetenumcount,clusternodeopenenum,'+
    'clusteropenenum,clusterregclosekey,clusterregcreatekey,clusterregdeletekey,'+
    'clusterregdeletevalue,clusterregenumkey,clusterregenumvalue,'+
    'clusterreggetkeysecurity,clusterregopenkey,clusterregqueryinfokey,'+
    'clusterregqueryvalue,clusterregsetkeysecurity,clusterregsetvalue,'+
    'clusterresourcecloseenum,clusterresourcecontrol,clusterresourceenum,'+
    'clusterresourcegetenumcount,clusterresourceopenenum,'+
    'clusterresourcetypecloseenum,clusterresourcetypecontrol,clusterresourcetypeenum,'+
    'clusterresourcetypegetenumcount,clusterresourcetypeopenenum,clustersplclose,'+
    'clustersplisalive,clustersplopen,clusworkercheckterminate,clusworkercreate,'+
    'clusworkerstart,clusworkerterminate,cm_add_empty_log_conf,'+
    'cm_add_empty_log_conf_ex,cm_add_id,cm_add_id_ex,cm_add_id_exa,cm_add_id_exw,'+
    'cm_add_ida,cm_add_idw,cm_add_range,cm_add_res_des,cm_add_res_des_ex,'+
    'cm_connect_machine,cm_connect_machinea,cm_connect_machinew,cm_create_devnode,'+
    'cm_create_devnode_ex,cm_create_devnode_exa,cm_create_devnode_exw,'+
    'cm_create_devnodea,cm_create_devnodew,cm_create_range_list,cm_delete_class_key,'+
    'cm_delete_class_key_ex,cm_delete_devnode_key,cm_delete_devnode_key_ex,'+
    'cm_delete_range,cm_detect_resource_conflict,cm_detect_resource_conflict_ex,'+
    'cm_disable_devnode,cm_disable_devnode_ex,cm_disconnect_machine,'+
    'cm_dup_range_list,cm_enable_devnode,cm_enable_devnode_ex,cm_enumerate_classes,'+
    'cm_enumerate_classes_ex,cm_enumerate_enumerators,cm_enumerate_enumerators_ex,'+
    'cm_enumerate_enumerators_exa,cm_enumerate_enumerators_exw,'+
    'cm_enumerate_enumeratorsa,cm_enumerate_enumeratorsw,cm_find_range,'+
    'cm_first_range,cm_free_log_conf,cm_free_log_conf_ex,cm_free_log_conf_handle,'+
    'cm_free_range_list,cm_free_res_des,cm_free_res_des_ex,cm_free_res_des_handle,'+
    'cm_free_resource_conflict_handle,cm_get_child,cm_get_child_ex,'+
    'cm_get_class_key_name,cm_get_class_key_name_ex,cm_get_class_key_name_exa,'+
    'cm_get_class_key_name_exw,cm_get_class_key_namea,cm_get_class_key_namew,'+
    'cm_get_class_name,cm_get_class_name_ex,cm_get_class_name_exa,'+
    'cm_get_class_name_exw,cm_get_class_namea,cm_get_class_namew,'+
    'cm_get_class_registry_property,cm_get_class_registry_propertya,'+
    'cm_get_class_registry_propertyw,cm_get_depth,cm_get_depth_ex,cm_get_device_id,'+
    'cm_get_device_id_ex,cm_get_device_id_exa,cm_get_device_id_exw,'+
    'cm_get_device_id_list,cm_get_device_id_list_ex,cm_get_device_id_list_exa,'+
    'cm_get_device_id_list_exw,cm_get_device_id_list_size,'+
    'cm_get_device_id_list_size_ex,cm_get_device_id_list_size_exa,'+
    'cm_get_device_id_list_size_exw,cm_get_device_id_list_sizea,'+
    'cm_get_device_id_list_sizew,cm_get_device_id_lista,cm_get_device_id_listw,'+
    'cm_get_device_id_size,cm_get_device_id_size_ex,cm_get_device_ida,'+
    'cm_get_device_idw,cm_get_device_interface_alias,'+
    'cm_get_device_interface_alias_ex,cm_get_device_interface_alias_exa,'+
    'cm_get_device_interface_alias_exw,cm_get_device_interface_aliasa,'+
    'cm_get_device_interface_aliasw,cm_get_device_interface_list,'+
    'cm_get_device_interface_list_ex,cm_get_device_interface_list_exa,'+
    'cm_get_device_interface_list_exw,cm_get_device_interface_list_size,'+
    'cm_get_device_interface_list_size_ex,cm_get_device_interface_list_size_exa,'+
    'cm_get_device_interface_list_size_exw,cm_get_device_interface_list_sizea,'+
    'cm_get_device_interface_list_sizew,cm_get_device_interface_lista,'+
    'cm_get_device_interface_listw,cm_get_devnode_custom_property,'+
    'cm_get_devnode_custom_property_ex,cm_get_devnode_custom_property_exa,'+
    'cm_get_devnode_custom_property_exw,cm_get_devnode_custom_propertya,'+
    'cm_get_devnode_custom_propertyw,cm_get_devnode_registry_property,'+
    'cm_get_devnode_registry_property_ex,cm_get_devnode_registry_property_exa,'+
    'cm_get_devnode_registry_property_exw,cm_get_devnode_registry_propertya,'+
    'cm_get_devnode_registry_propertyw,cm_get_devnode_status,'+
    'cm_get_devnode_status_ex,cm_get_first_log_conf,cm_get_first_log_conf_ex,'+
    'cm_get_global_state,cm_get_global_state_ex,cm_get_hardware_profile_info,'+
    'cm_get_hardware_profile_info_ex,cm_get_hardware_profile_info_exa,'+
    'cm_get_hardware_profile_info_exw,cm_get_hardware_profile_infoa,'+
    'cm_get_hardware_profile_infow,cm_get_hw_prof_flags,cm_get_hw_prof_flags_ex,'+
    'cm_get_hw_prof_flags_exa,cm_get_hw_prof_flags_exw,cm_get_hw_prof_flagsa,'+
    'cm_get_hw_prof_flagsw,cm_get_log_conf_priority,cm_get_log_conf_priority_ex,'+
    'cm_get_next_log_conf,cm_get_next_log_conf_ex,cm_get_next_res_des,'+
    'cm_get_next_res_des_ex,cm_get_parent,cm_get_parent_ex,cm_get_res_des_data,'+
    'cm_get_res_des_data_ex,cm_get_res_des_data_size,cm_get_res_des_data_size_ex,'+
    'cm_get_resource_conflict_count,cm_get_resource_conflict_details,'+
    'cm_get_resource_conflict_detailsa,cm_get_resource_conflict_detailsw,'+
    'cm_get_sibling,cm_get_sibling_ex,cm_get_version,cm_get_version_ex,'+
    'cm_intersect_range_list,cm_invert_range_list,cm_is_dock_station_present,'+
    'cm_is_dock_station_present_ex,cm_is_version_available,'+
    'cm_is_version_available_ex,cm_locate_devnode,cm_locate_devnode_ex,'+
    'cm_locate_devnode_exa,cm_locate_devnode_exw,cm_locate_devnodea,'+
    'cm_locate_devnodew,cm_merge_range_list,cm_modify_res_des,cm_modify_res_des_ex,'+
    'cm_move_devnode,cm_move_devnode_ex,cm_next_range,cm_open_class_key,'+
    'cm_open_class_key_ex,cm_open_class_key_exa,cm_open_class_key_exw,'+
    'cm_open_class_keya,cm_open_class_keyw,cm_open_devnode_key,'+
    'cm_open_devnode_key_ex,cm_query_and_remove_subtree,'+
    'cm_query_and_remove_subtree_ex,cm_query_and_remove_subtree_exa,'+
    'cm_query_and_remove_subtree_exw,cm_query_and_remove_subtreea,'+
    'cm_query_and_remove_subtreew,cm_query_arbitrator_free_data,'+
    'cm_query_arbitrator_free_data_ex,cm_query_arbitrator_free_size,'+
    'cm_query_arbitrator_free_size_ex,cm_query_remove_subtree,'+
    'cm_query_remove_subtree_ex,cm_query_resource_conflict_list,'+
    'cm_reenumerate_devnode,cm_reenumerate_devnode_ex,cm_register_device_driver,'+
    'cm_register_device_driver_ex,cm_register_device_interface,'+
    'cm_register_device_interface_ex,cm_register_device_interface_exa,'+
    'cm_register_device_interface_exw,cm_register_device_interfacea,'+
    'cm_register_device_interfacew,cm_remove_subtree,cm_remove_subtree_ex,'+
    'cm_request_device_eject,cm_request_device_eject_ex,cm_request_device_eject_exa,'+
    'cm_request_device_eject_exw,cm_request_device_ejecta,cm_request_device_ejectw,'+
    'cm_request_eject_pc,cm_request_eject_pc_ex,cm_run_detection,cm_run_detection_ex,'+
    'cm_set_class_registry_property,cm_set_class_registry_propertya,'+
    'cm_set_class_registry_propertyw,cm_set_devnode_problem,'+
    'cm_set_devnode_problem_ex,cm_set_devnode_registry_property,'+
    'cm_set_devnode_registry_property_ex,cm_set_devnode_registry_property_exa,'+
    'cm_set_devnode_registry_property_exw,cm_set_devnode_registry_propertya,'+
    'cm_set_devnode_registry_propertyw,cm_set_hw_prof,cm_set_hw_prof_ex,'+
    'cm_set_hw_prof_flags,cm_set_hw_prof_flags_ex,cm_set_hw_prof_flags_exa,'+
    'cm_set_hw_prof_flags_exw,cm_set_hw_prof_flagsa,cm_set_hw_prof_flagsw,'+
    'cm_setup_devnode,cm_setup_devnode_ex,cm_test_range_available,'+
    'cm_uninstall_devnode,cm_uninstall_devnode_ex,cm_unregister_device_interface,'+
    'cm_unregister_device_interface_ex,cm_unregister_device_interface_exa,'+
    'cm_unregister_device_interface_exw,cm_unregister_device_interfacea,'+
    'cm_unregister_device_interfacew,cmcheckcolors,cmcheckcolorsingamut,cmcheckrgbs,'+
    'cmconvertcolornametoindex,cmconvertindextocolorname,cmcreatedevicelinkprofile,'+
    'cmcreatemultiprofiletransform,cmcreateprofile,cmcreateprofilew,'+
    'cmcreatetransform,cmcreatetransformext,cmcreatetransformextw,cmcreatetransformw,'+
    'cmdbatnotification,cmdchecktemp,cmdchecktempinit,cmdeletetransform,cmgetinfo,'+
    'cmgetnamedprofileinfo,cmisprofilevalid,cmp_getblockeddriverinfo,'+
    'cmp_getserversidedeviceinstallflags,cmp_init_detection,cmp_registernotification,'+
    'cmp_report_logon,cmp_unregisternotification,cmp_waitnopendinginstallevents,'+
    'cmp_waitservicesavailable,cmpi,cmpmem,cmregistercallback,cmtranslatecolors,'+
    'cmtranslatergb,cmtranslatergbs,cmtranslatergbsext,cmunregistercallback,'+
    'coaddrefserverprocess,coallowsetforegroundwindow,cobuildversion,cocancelcall,'+
    'cocopyproxy,cocreateactivity,cocreatefreethreadedmarshaler,cocreateguid,'+
    'cocreateinstance,cocreateinstanceex,cocreateobjectincontext,'+
    'cocreatestdtrustable,codeactivateobject,codecopen,codisablecallcancellation,'+
    'codisconnectobject,codosdatetimetofiletime,coenablecallcancellation,'+
    'coenterservicedomain,cofiletimenow,cofiletimetodosdatetime,cofreealllibraries,'+
    'cofreelibrary,cofreeunusedlibraries,cofreeunusedlibrariesex,cogetapartmentid,'+
    'cogetcallcontext,cogetcallertid,cogetcancelobject,cogetclassobject,'+
    'cogetclassobjectfromurl,cogetclassversion,cogetcontexttoken,'+
    'cogetcurrentlogicalthreadid,cogetcurrentprocess,cogetdefaultcontext,'+
    'cogetinstancefromfile,cogetinstancefromistorage,cogetinterceptor,'+
    'cogetinterceptorfromtypeinfo,cogetinterfaceandreleasestream,cogetmalloc,'+
    'cogetmarshalsizemax,cogetobject,cogetobjectcontext,cogetprocessidentifier,'+
    'cogetpsclsid,cogetstandardmarshal,cogetstate,cogetstdmarshalex,'+
    'cogetsystemsecuritypermissions,cogettreatasclass,coimpersonateclient,'+
    'coinitialize,coinitializeex,coinitializesecurity,coinitializewo,coinitializewow,'+
    'coinstall,cointernetcombineurl,cointernetcompareurl,'+
    'cointernetcreatesecuritymanager,cointernetcreatezonemanager,'+
    'cointernetgetprotocolflags,cointernetgetsecurityurl,cointernetgetsession,'+
    'cointernetisfeatureenabled,cointernetisfeatureenabledforurl,'+
    'cointernetisfeaturezoneelevationenabled,cointernetparseurl,cointernetqueryinfo,'+
    'cointernetsetfeatureenabled,coinvalidateremotemachinebindings,'+
    'coishandlerconnected,coisole1class,coleaveservicedomain,'+
    'collectciisapiperformancedata,collectciperformancedata,'+
    'collectdnsperformancedata,collectfilterperformancedata,'+
    'collectncpsrvperformancedata,collectodbcperfdata,collectsslperformancedata,'+
    'coloadlibrary,coloadservices,colockobjectexternal,coloradjustluma,'+
    'colorcorrectpalette,colordialog,colorhlstorgb,colormatchtotarget,colorrgbtohls,'+
    'comarshalhresult,comarshalinterface,comarshalinterthreadinterfaceinstream,'+
    'combinerecordsinblob,combinergn,combinetransform,comboboxexitem,combsorta,'+
    'combsortd,comdbclaimnextfreeport,comdbclaimport,comdbclose,'+
    'comdbgetcurrentportusage,comdbopen,comdbreleaseport,comdbresizedatabase,'+
    'commandlinefrommsidescriptor,commandlinetoargv,commandlinetoargvw,'+
    'commconfigdialog,commconfigdialoga,commconfigdialogw,commdlgextendederror,'+
    'commitspooldata,commiturlcacheentry,commiturlcacheentrya,commiturlcacheentryw,'+
    'commonpropertysheetui,commonpropertysheetuia,commonpropertysheetuiw,'+
    'comp_alloc_compress_memory,comp_free_compress_memory,comp_read_input,'+
    'compactnetworkbuffer,compareaddresses,comparefiletime,compareframedestaddress,'+
    'compareframesourceaddress,comparerawaddresses,comparesecurityids,comparestring,'+
    'comparestringa,comparestringw,compatflagsfromclsid,completeauthtoken,'+
    'compress_block,compressphonenumber,compresstext,comps_cstdstubbuffer_addref,'+
    'comps_cstdstubbuffer_connect,comps_cstdstubbuffer_countrefs,'+
    'comps_cstdstubbuffer_debugserverqueryinterface'+
    'comps_cstdstubbuffer_debugserverrelease,comps_cstdstubbuffer_disconnect,'+
    'comps_cstdstubbuffer_invoke,comps_cstdstubbuffer_isiidsupported,'+
    'comps_cstdstubbuffer_queryinterface,comps_iunknown_addref_proxy,'+
    'comps_iunknown_queryinterface_proxy,comps_iunknown_release_proxy,'+
    'comps_ndrclientcall2,comps_ndrclientcall2_va,comps_ndrcstdstubbuffer_release,'+
    'comps_ndrcstdstubbuffer2_release,comps_ndrdllcanunloadnow,'+
    'comps_ndrdllgetclassobject,comps_ndrdllregisterproxy,'+
    'comps_ndrdllunregisterproxy,comps_ndrstubcall2,comps_ndrstubforwardingfunction,'+
    'computeaccesstokenfromcodeauthzlevel,computeinvcmap,computerclassinstaller,'+
    'comsvcsexceptionfilter,comsvcslogerror,configureias,configureport,'+
    'configureporta,configureportw,connect,connectdlgproc,connectnamedpipe,'+
    'connecttold64in32server,connecttoprinterdlg,consolemenucontrol,'+
    'continuecapturing,continuedebugevent,controlprintprocessor,controlservice,'+
    'controltrace,controltracea,controltracew,convertaccesstosecuritydescriptor,'+
    'convertaccesstosecuritydescriptora,convertaccesstosecuritydescriptorw,'+
    'convertansidevmodetounicodedevmode,convertatjobstotasks,convertcolornametoindex,'+
    'convertdefaultlocale,convertfibertothread,convertindextocolorname,'+
    'convertsdtostringsdrootdomain,convertsdtostringsdrootdomaina,'+
    'convertsdtostringsdrootdomainw,convertsecdescriptortovariant,'+
    'convertsecuritydescriptortoaccess,convertsecuritydescriptortoaccessa,'+
    'convertsecuritydescriptortoaccessnamed,convertsecuritydescriptortoaccessnameda,'+
    'convertsecuritydescriptortoaccessnamedw,convertsecuritydescriptortoaccessw,'+
    'convertsecuritydescriptortosecdes'+
    'convertsecuritydescriptortostringsecuritydescriptor'+
    'convertsecuritydescriptortostringsecuritydescriptora'+
    'convertsecuritydescriptortostringsecuritydescriptorw,convertsidtostringsid,'+
    'convertsidtostringsida,convertsidtostringsidw,convertstringsdtosddomain,'+
    'convertstringsdtosddomaina,convertstringsdtosddomainw,'+
    'convertstringsdtosdrootdomain,convertstringsdtosdrootdomaina,'+
    'convertstringsdtosdrootdomainw'+
    'convertstringsecuritydescriptortosecuritydescriptor'+
    'convertstringsecuritydescriptortosecuritydescriptora'+
    'convertstringsecuritydescriptortosecuritydescriptorw,convertstringsidtosid,'+
    'convertstringsidtosida,convertstringsidtosidw,convertthreadtofiber,'+
    'converttoautoinheritprivateobjectsecurity,convertunicodedevmodetoansidevmode,'+
    'copacket,copy_block,copy_data_to_output,copyacceleratortable,'+
    'copyacceleratortablea,copyacceleratortablew,copyb,copybindinfo,copyblkandwht,'+
    'copydatetime,copydropfilesfrom16,copydropfilesfrom32,copyenhmetafile,'+
    'copyenhmetafilea,copyenhmetafilew,copyfile,copyfilea,copyfileex,copyfileexa,'+
    'copyfileexw,copyfilew,copyicon,copyimage,copylzfile,copymetafile,copymetafilea,'+
    'copymetafilew,copymsg,copyparameters,copyprofiledirectory,copyprofiledirectorya,'+
    'copyprofiledirectoryex,copyprofiledirectoryexa,copyprofiledirectoryexw,'+
    'copyprofiledirectoryw,copyrect,copysid,copystgmedium,copysystemprofile,'+
    'coqueryauthenticationservices,coqueryclientblanket,coqueryproxyblanket,'+
    'coqueryreleaseobject,coreactivateobject,coregisterchannelhook,'+
    'coregisterclassobject,coregisterinitializespy,coregistermallocspy,'+
    'coregistermessagefilter,coregisterpsclsid,coregistersurrogate,'+
    'coregistersurrogateex,coreleasemarshaldata,coreleaseserverprocess,'+
    'coresumeclassobjects,coretireserver,coreverttoself,corevokeclassobject,'+
    'corevokeinitializespy,corevokemallocspy,cosetcancelobject,cosetproxyblanket,'+
    'cosetstate,cosuspendclassobjects,coswitchcallcontext,cotaskmemalloc,'+
    'cotaskmemfree,cotaskmemrealloc,cotestcancel,cotreatasclass,couninitialize,'+
    'counloadingwo,counloadingwow,counmarshalhresult,counmarshalinterface,count_len,'+
    'countclipboardformats,counthilites,countnameparts,coverifytrust,'+
    'cowaitformultiplehandles,cpinfoex,cpu_createthread,cracksinglename,creat,'+
    'create_array,create_ones_table,create_slot_lookup_table,create_trees,'+
    'createacceleratortable,createacceleratortablea,createacceleratortablew,'+
    'createactctx,createactctxa,createactctxw,createactivityinmta,'+
    'createaddressdatabase,createantimoniker,createasyncbindctx,createasyncbindctxex,'+
    'createbatmeter,createbindctx,createbitmap,createbitmapindirect,createblob,'+
    'createbrushindirect,createcab,createcapture,createcaret,createclassmoniker,'+
    'createclustergroup,createclusternotifyport,createclusterresource,'+
    'createclusterresourcetype,createcodeauthzlevel,createcolorspace,'+
    'createcolorspacea,createcolorspacew,createcolortransform,createcolortransforma,'+
    'createcolortransformw,createcompatiblebitmap,createcompatibledc,'+
    'createconsolescreenbuffer,createcursor,created3drmpmeshvisual,'+
    'createdataadviseholder,createdatacache,createdc,createdca,createdcw,'+
    'createddrawsurfaceondib,createdesktop,createdesktopa,createdesktopw,'+
    'createdevicelinkprofile,createdialogindirectparam,createdialogindirectparama,'+
    'createdialogindirectparamw,createdialogparam,createdialogparama,'+
    'createdialogparamw,createdibitmap,createdibpatternbrush,createdibpatternbrushpt,'+
    'createdibsection,createdirectory,createdirectorya,createdirectoryex,'+
    'createdirectoryexa,createdirectoryexw,createdirectoryw,creatediscardablebitmap,'+
    'createdisptypeinfo,createeditablestream,createellipticrgn,'+
    'createellipticrgnindirect,createenhmetafile,createenhmetafilea,'+
    'createenhmetafilew,createenvironmentblock,createerrorinfo,createerrorlogentry,'+
    'createevent,createeventa,createeventw,createfiber,createfiberex,createfile,'+
    'createfilea,createfilemapping,createfilemappinga,createfilemappingw,'+
    'createfilemoniker,createfilew,createfilter,createfont,createfonta,'+
    'createfontindirect,createfontindirecta,createfontindirectex,'+
    'createfontindirectexa,createfontindirectexw,createfontindirectw,createfontw,'+
    'createformatenumerator,createframe,creategenericcomposite,creategpolink,'+
    'creategroup,creategroupa,creategroupex,creategroupexa,creategroupexw,'+
    'creategroupw,createhalftonepalette,createhandofftable,createhardlink,'+
    'createhardlinka,createhardlinkw,createhatchbrush,createic,createica,createicon,'+
    'createiconfromresource,createiconfromresourceex,createiconindirect,createicw,'+
    'createilockbytesonhglobal,createinterface,createiocompletionport,'+
    'createipforwardentry,createipnetentry,createiprop,createitemmoniker,'+
    'createjobobject,createjobobjecta,createjobobjectw,createjobset,createlinkfile,'+
    'createlinkfilea,createlinkfileex,createlinkfileexa,createlinkfileexw,'+
    'createlinkfilew,createlocaladminaccount,createlocaladminaccountex,'+
    'createlocaluseraccount,createmailslot,createmailslota,createmailslotw,'+
    'createmappedbitmap,createmd5ssohash,createmdiwindow,createmdiwindowa,'+
    'createmdiwindoww,creatememoryresourcenotification,createmenu,createmetafile,'+
    'createmetafilea,createmetafilew,createmimemap,createmmf,createmrulist,'+
    'createmrulistw,createmultiprofiletransform,createmutex,createmutexa,'+
    'createmutexw,createnamedpipe,createnamedpipea,createnamedpipew,'+
    'createnewsecuritydescriptor,createnlssecuritydescriptor,createnppinterface,'+
    'createntmsmedia,createntmsmediaa,createntmsmediapool,createntmsmediapoola,'+
    'createntmsmediapoolw,createntmsmediaw,createobjectheap,createobjrefmoniker,'+
    'createoleadviseholder,createpalette,createpassword,createpatternbrush,createpen,'+
    'createpenindirect,createpipe,createpointermoniker,createpolygonrgn,'+
    'createpolypolygonrgn,createpopupmenu,createprinteric,'+
    'createprivateobjectsecurity,createprivateobjectsecurityex,'+
    'createprivateobjectsecuritywithmultipleinheritance,createprocess,createprocessa,'+
    'createprocessasuser,createprocessasusera,createprocessasusersecure,'+
    'createprocessasuserw,createprocessinternal,createprocessinternala,'+
    'createprocessinternalw,createprocessinternalwsecure,createprocessw,'+
    'createprocesswithlogon,createprocesswithlogonw,createprofilefromlogcolorspace,'+
    'createprofilefromlogcolorspacea,createprofilefromlogcolorspacew,'+
    'createpropertydatabase,createpropertysheetpage,createpropertysheetpagea,'+
    'createpropertysheetpagew,createprotocol,createproxyarpentry,createrectrgn,'+
    'createrectrgnindirect,createremotethread,createrestrictedtoken,'+
    'createroundrectrgn,creatersopquery,createscalablefontresource,'+
    'createscalablefontresourcea,createscalablefontresourcew,createsecuritypage,'+
    'createsemaphore,createsemaphorea,createsemaphorew,createservice,createservicea,'+
    'createservicew,createsnapshot,createsockethandle,createsocketport,'+
    'createsolidbrush,createstatuswindow,createstatuswindowa,createstatuswindoww,'+
    'createstdaccessibleobject,createstdaccessibleproxy,createstdaccessibleproxya,'+
    'createstdaccessibleproxyw,createstddispatch,createstdprogressindicator,'+
    'createstreamonhglobal,createtable,createtapepartition,createthread,'+
    'createtimerqueue,createtimerqueuetimer,createtoolbarex,createtoolhelp32snapshot,'+
    'createtraceinstanceid,createtypelib,createtypelib2,createupdowncontrol,'+
    'createurlcachecontainer,createurlcachecontainera,createurlcachecontainerw,'+
    'createurlcacheentry,createurlcacheentrya,createurlcacheentryw,'+
    'createurlcachegroup,createurlfile,createurlmoniker,createurlmonikerex,'+
    'createuserprofile,createuserprofilea,createuserprofileex,createuserprofileexa,'+
    'createuserprofileexw,createuserprofilew,createvirtualbuffer,createwaitabletimer,'+
    'createwaitabletimera,createwaitabletimerw,createwaitevent,'+
    'createwaiteventbinding,createwaittimer,createwellknownsid,createwindowex,'+
    'createwindowexa,createwindowexw,createwindowstation,createwindowstationa,'+
    'createwindowstationw,creddelete,creddeletea,creddeletew,credenumerate,'+
    'credenumeratea,credenumeratew,credfree,credgetsessiontypes,credgettargetinfo,'+
    'credgettargetinfoa,credgettargetinfow,credismarshaledcredential,'+
    'credismarshaledcredentiala,credismarshaledcredentialw,credmarshalcredential,'+
    'credmarshalcredentiala,credmarshalcredentialw,credmarshaltargetinfo,'+
    'credpconvertcredential,credpconverttargetinfo,credpdecodecredential,'+
    'credpencodecredential,credprofileloaded,credread,credreada,'+
    'credreaddomaincredentials,credreaddomaincredentialsa,credreaddomaincredentialsw,'+
    'credreadw,credrename,credrenamea,credrenamew,creduicmdlinepromptforcredentials,'+
    'creduicmdlinepromptforcredentialsa,creduicmdlinepromptforcredentialsw,'+
    'creduiconfirmcredentials,creduiconfirmcredentialsa,creduiconfirmcredentialsw,'+
    'creduiparseusername,creduiparseusernamea,creduiparseusernamew,'+
    'creduipromptforcredentials,creduipromptforcredentialsa,'+
    'creduipromptforcredentialsw,creduireadssocred,creduireadssocredw,'+
    'creduistoressocred,creduistoressocredw,credunmarshalcredential,'+
    'credunmarshalcredentiala,credunmarshalcredentialw,credwrite,credwritea,'+
    'credwritedomaincredentials,credwritedomaincredentialsa,'+
    'credwritedomaincredentialsw,credwritew,criticaldevicecoinstaller,crtempfiles,'+
    'cryptacquirecertificateprivatekey,cryptacquirecontext,cryptacquirecontexta,'+
    'cryptacquirecontextw,cryptbinarytostring,cryptbinarytostringa,'+
    'cryptbinarytostringw,cryptcatadminacquirecontext,cryptcatadminaddcatalog,'+
    'cryptcatadmincalchashfromfilehandle,cryptcatadminenumcatalogfromhash,'+
    'cryptcatadminpauseserviceforbackup,cryptcatadminreleasecatalogcontext,'+
    'cryptcatadminreleasecontext,cryptcatadminremovecatalog,'+
    'cryptcatadminresolvecatalogpath,cryptcatcataloginfofromcontext,cryptcatcdfclose,'+
    'cryptcatcdfenumattributes,cryptcatcdfenumattributeswithcdftag,'+
    'cryptcatcdfenumcatattributes,cryptcatcdfenummembers,'+
    'cryptcatcdfenummembersbycdftag,cryptcatcdfenummembersbycdftagex,cryptcatcdfopen,'+
    'cryptcatclose,cryptcatenumerateattr,cryptcatenumeratecatattr,'+
    'cryptcatenumeratemember,cryptcatgetattrinfo,cryptcatgetcatattrinfo,'+
    'cryptcatgetmemberinfo,cryptcathandlefromstore,cryptcatopen,cryptcatpersiststore,'+
    'cryptcatputattrinfo,cryptcatputcatattrinfo,cryptcatputmemberinfo,'+
    'cryptcatstorefromhandle,cryptcloseasynchandle,cryptcontextaddref,'+
    'cryptcreateasynchandle,cryptcreatehash,cryptcreatekeyidentifierfromcsp,'+
    'cryptdecodemessage,cryptdecodeobject,cryptdecodeobjectex,cryptdecrypt,'+
    'cryptdecryptandverifymessagesignature,cryptdecryptmessage,cryptderivekey,'+
    'cryptdestroyhash,cryptdestroykey,cryptduplicatehash,cryptduplicatekey,'+
    'cryptencodeobject,cryptencodeobjectex,cryptencrypt,cryptencryptmessage,'+
    'cryptenumkeyidentifierproperties,cryptenumoidfunction,cryptenumoidinfo,'+
    'cryptenumproviders,cryptenumprovidersa,cryptenumprovidersw,'+
    'cryptenumprovidertypes,cryptenumprovidertypesa,cryptenumprovidertypesw,'+
    'cryptexportkey,cryptexportpkcs8,cryptexportpublickeyinfo,'+
    'cryptexportpublickeyinfoex,cryptfindcertificatekeyprovinfo,'+
    'cryptfindlocalizedname,cryptfindoidinfo,cryptformatobject,'+
    'cryptfreeoidfunctionaddress,cryptgenkey,cryptgenrandom,cryptgetasyncparam,'+
    'cryptgetdefaultoiddlllist,cryptgetdefaultoidfunctionaddress,'+
    'cryptgetdefaultprovider,cryptgetdefaultprovidera,cryptgetdefaultproviderw,'+
    'cryptgethashparam,cryptgetkeyidentifierproperty,cryptgetkeyparam,'+
    'cryptgetmessagecertificates,cryptgetmessagesignercount,cryptgetobjecturl,'+
    'cryptgetoidfunctionaddress,cryptgetoidfunctionvalue,cryptgetprovparam,'+
    'cryptgetuserkey,crypthashcertificate,crypthashdata,crypthashmessage,'+
    'crypthashpublickeyinfo,crypthashsessionkey,crypthashtobesigned,cryptimportkey,'+
    'cryptimportpkcs8,cryptimportpublickeyinfo,cryptimportpublickeyinfoex,'+
    'cryptinitoidfunctionset,cryptinstallcancelretrieval,cryptinstalldefaultcontext,'+
    'cryptinstalloidfunctionaddress,cryptloadsip,cryptmemalloc,cryptmemfree,'+
    'cryptmemrealloc,cryptmsgcalculateencodedlength,cryptmsgclose,cryptmsgcontrol,'+
    'cryptmsgcountersign,cryptmsgcountersignencoded,cryptmsgduplicate,'+
    'cryptmsgencodeandsignctl,cryptmsggetandverifysigner,cryptmsggetparam,'+
    'cryptmsgopentodecode,cryptmsgopentoencode,cryptmsgsignctl,cryptmsgupdate,'+
    'cryptmsgverifycountersignatureencoded,cryptmsgverifycountersignatureencodedex,'+
    'cryptprotectdata,cryptqueryobject,cryptregisterdefaultoidfunction,'+
    'cryptregisteroidfunction,cryptregisteroidinfo,cryptreleasecontext,'+
    'cryptretrieveobjectbyurl,cryptretrieveobjectbyurla,cryptretrieveobjectbyurlw,'+
    'cryptsetasyncparam,cryptsethashparam,cryptsetkeyidentifierproperty,'+
    'cryptsetkeyparam,cryptsetoidfunctionvalue,cryptsetprovider,cryptsetprovidera,'+
    'cryptsetproviderex,cryptsetproviderexa,cryptsetproviderexw,cryptsetproviderw,'+
    'cryptsetprovparam,cryptsignandencodecertificate,cryptsignandencryptmessage,'+
    'cryptsigncertificate,cryptsignhash,cryptsignhasha,cryptsignhashw,'+
    'cryptsignmessage,cryptsignmessagewithkey,cryptsipaddprovider,'+
    'cryptsipcreateindirectdata,cryptsipgetsigneddatamsg,cryptsipload,'+
    'cryptsipputsigneddatamsg,cryptsipremoveprovider,cryptsipremovesigneddatamsg,'+
    'cryptsipretrievesubjectguid,cryptsipretrievesubjectguidforcatalogfile,'+
    'cryptsipverifyindirectdata,cryptstringtobinary,cryptstringtobinarya,'+
    'cryptstringtobinaryw,cryptuidlgcertmgr,cryptuidlgfreecacontext,'+
    'cryptuidlgselectca,cryptuidlgselectcertificate,cryptuidlgselectcertificatea,'+
    'cryptuidlgselectcertificatefromstore,cryptuidlgselectcertificatew,'+
    'cryptuidlgselectstore,cryptuidlgselectstorea,cryptuidlgselectstorew,'+
    'cryptuidlgviewcertificate,cryptuidlgviewcertificatea,'+
    'cryptuidlgviewcertificateproperties,cryptuidlgviewcertificatepropertiesa,'+
    'cryptuidlgviewcertificatepropertiesw,cryptuidlgviewcertificatew,'+
    'cryptuidlgviewcontext,cryptuidlgviewcrl,cryptuidlgviewcrla,cryptuidlgviewcrlw,'+
    'cryptuidlgviewctl,cryptuidlgviewctla,cryptuidlgviewctlw,'+
    'cryptuidlgviewsignerinfo,cryptuidlgviewsignerinfoa,cryptuidlgviewsignerinfow,'+
    'cryptuifreecertificatepropertiespages,cryptuifreecertificatepropertiespagesa,'+
    'cryptuifreecertificatepropertiespagesw,cryptuifreeviewsignaturespages,'+
    'cryptuifreeviewsignaturespagesa,cryptuifreeviewsignaturespagesw,'+
    'cryptuigetcertificatepropertiespages,cryptuigetcertificatepropertiespagesa,'+
    'cryptuigetcertificatepropertiespagesw,cryptuigetviewsignaturespages,'+
    'cryptuigetviewsignaturespagesa,cryptuigetviewsignaturespagesw,'+
    'cryptuistartcertmgr,cryptuiwizbuildctl,cryptuiwizcertrequest,'+
    'cryptuiwizcreatecertrequestnods,cryptuiwizdigitalsign,cryptuiwizexport,'+
    'cryptuiwizfreecertrequestnods,cryptuiwizfreedigitalsigncontext,cryptuiwizimport,'+
    'cryptuiwizquerycertrequestnods,cryptuiwizsubmitcertrequestnods,'+
    'cryptuninstallcancelretrieval,cryptuninstalldefaultcontext,cryptunprotectdata,'+
    'cryptunregisterdefaultoidfunction,cryptunregisteroidfunction,'+
    'cryptunregisteroidinfo,cryptverifycertificatesignature,'+
    'cryptverifycertificatesignatureex,cryptverifydetachedmessagehash,'+
    'cryptverifydetachedmessagesignature,cryptverifymessagehash,'+
    'cryptverifymessagesignature,cryptverifymessagesignaturewithkey,'+
    'cryptverifysignature,cryptverifysignaturea,cryptverifysignaturew,'+
    'cscbeginsynchronization,cscbeginsynchronizationw,csccheckshareonline,'+
    'csccheckshareonlinea,csccheckshareonlineex,csccheckshareonlineexw,'+
    'csccheckshareonlinew,csccopyreplica,csccopyreplicaa,csccopyreplicaw,cscdelete,'+
    'cscdeletea,cscdeletew,cscdoenabledisable,cscdolocalrename,cscdolocalrenamea,'+
    'cscdolocalrenameex,cscdolocalrenameexw,cscdolocalrenamew,'+
    'cscencryptdecryptdatabase,cscendsynchronization,cscendsynchronizationw,'+
    'cscenumforstats,cscenumforstatsa,cscenumforstatsex,cscenumforstatsexa,'+
    'cscenumforstatsexw,cscenumforstatsw,cscfillsparsefiles,cscfillsparsefilesa,'+
    'cscfillsparsefilesw,cscfindclose,cscfindfirstfile,cscfindfirstfilea,'+
    'cscfindfirstfileforsid,cscfindfirstfileforsida,cscfindfirstfileforsidw,'+
    'cscfindfirstfilew,cscfindnextfile,cscfindnextfilea,cscfindnextfilew,'+
    'cscfreespace,cscgetspaceusage,cscgetspaceusagea,cscgetspaceusagew,'+
    'csciscscenabled,cscisserveroffline,cscisserverofflinea,cscisserverofflinew,'+
    'cscmergeshare,cscmergesharea,cscmergesharew,cscpinfile,cscpinfilea,cscpinfilew,'+
    'cscpurgeunpinnedfiles,cscquerydatabasestatus,cscqueryfilestatus,'+
    'cscqueryfilestatusa,cscqueryfilestatusex,cscqueryfilestatusexa,'+
    'cscqueryfilestatusexw,cscqueryfilestatusw,cscquerysharestatus,'+
    'cscquerysharestatusa,cscquerysharestatusw,cscreateclassstore,cscsetmaxspace,'+
    'cscshareidtosharename,csctransitionserveronline,csctransitionserveronlinea,'+
    'csctransitionserveronlinew,cscunpinfile,cscunpinfilea,cscunpinfilew,csenumapps,'+
    'csgetappcategories,csgetclassaccess,csgetclassstore,csgetclassstorepath,'+
    'csrallocatecapturebuffer,csrallocatemessagepointer,csrcapturemessagebuffer,'+
    'csrcapturemessagemultiunicodestringsinplace,csrcapturemessagestring,'+
    'csrcapturetimeout,csrclientcallserver,csrclientconnecttoserver,'+
    'csregisterappcategory,csrfreecapturebuffer,csrgetprocessid,'+
    'csridentifyalertablethread,csrnewthread,csrprobeforread,csrprobeforwrite,'+
    'csrsetpriorityclass,cstdstubbuffer_addref,cstdstubbuffer_connect,'+
    'cstdstubbuffer_countrefs,cstdstubbuffer_debugserverqueryinterface,'+
    'cstdstubbuffer_debugserverrelease,cstdstubbuffer_disconnect,'+
    'cstdstubbuffer_invoke,cstdstubbuffer_isiidsupported,'+
    'cstdstubbuffer_queryinterface,cstsorta,cstsortd,csumcompute,'+
    'csunregisterappcategory,ct_init,ct_tally,cteallocatestring,cteblock,'+
    'cteblockwithtracker,cteinitevent,cteinitialize,cteinitstring,cteinittimer,'+
    'cteinsertblocktracker,ctelogevent,cteremoveblocktracker,ctermid,'+
    'cteschedulecriticalevent,ctescheduledelayedevent,ctescheduleevent,ctesignal,'+
    'ctestarttimer,ctesystemuptime,ctime,currentmonitorteb,currenttimezonename,'+
    'currentutcoffsetinhours,currentutcoffsetinminutes,cursorliblockdbc,'+
    'cursorliblockdesc,cursorliblockstmt,cursorlibtransact,cuserid,'+
    'd3dxassembleshader,d3dxassembleshaderfromfile,d3dxassembleshaderfromfilea,'+
    'd3dxassembleshaderfromfilew,d3dxassembleshaderfromresource,'+
    'd3dxassembleshaderfromresourcea,d3dxassembleshaderfromresourcew,'+
    'd3dxboxboundprobe,d3dxcheckcubetexturerequirements,d3dxchecktexturerequirements,'+
    'd3dxcheckvolumetexturerequirements,d3dxcleanmesh,d3dxcoloradjustcontrast,'+
    'd3dxcoloradjustsaturation,d3dxcomputeboundingbox,d3dxcomputeboundingsphere,'+
    'd3dxcomputenormalmap,d3dxcomputenormals,d3dxcomputetangent,'+
    'd3dxconvertmeshsubsettosinglestrip,d3dxconvertmeshsubsettostrips,'+
    'd3dxcpuoptimizations,d3dxcreatebox,d3dxcreatebuffer,d3dxcreatecubetexture,'+
    'd3dxcreatecubetexturefromfile,d3dxcreatecubetexturefromfilea,'+
    'd3dxcreatecubetexturefromfileex,d3dxcreatecubetexturefromfileexa,'+
    'd3dxcreatecubetexturefromfileexw,d3dxcreatecubetexturefromfileinmemory,'+
    'd3dxcreatecubetexturefromfileinmemoryex,d3dxcreatecubetexturefromfilew,'+
    'd3dxcreatecubetexturefromresource,d3dxcreatecubetexturefromresourcea,'+
    'd3dxcreatecubetexturefromresourceex,d3dxcreatecubetexturefromresourceexa,'+
    'd3dxcreatecubetexturefromresourceexw,d3dxcreatecubetexturefromresourcew,'+
    'd3dxcreatecylinder,d3dxcreateeffect,d3dxcreateeffectfromfile,'+
    'd3dxcreateeffectfromfilea,d3dxcreateeffectfromfilew,'+
    'd3dxcreateeffectfromresource,d3dxcreateeffectfromresourcea,'+
    'd3dxcreateeffectfromresourcew,d3dxcreatefont,d3dxcreatefontindirect,'+
    'd3dxcreatematrixstack,d3dxcreatemesh,d3dxcreatemeshfvf,'+
    'd3dxcreatepmeshfromstream,d3dxcreatepolygon,d3dxcreaterendertoenvmap,'+
    'd3dxcreaterendertosurface,d3dxcreateskinmesh,d3dxcreateskinmeshfrommesh,'+
    'd3dxcreateskinmeshfvf,d3dxcreatesphere,d3dxcreatespmesh,d3dxcreatesprite,'+
    'd3dxcreateteapot,d3dxcreatetext,d3dxcreatetexta,d3dxcreatetexture,'+
    'd3dxcreatetexturefromfile,d3dxcreatetexturefromfilea,'+
    'd3dxcreatetexturefromfileex,d3dxcreatetexturefromfileexa,'+
    'd3dxcreatetexturefromfileexw,d3dxcreatetexturefromfileinmemory,'+
    'd3dxcreatetexturefromfileinmemoryex,d3dxcreatetexturefromfilew,'+
    'd3dxcreatetexturefromresource,d3dxcreatetexturefromresourcea,'+
    'd3dxcreatetexturefromresourceex,d3dxcreatetexturefromresourceexa,'+
    'd3dxcreatetexturefromresourceexw,d3dxcreatetexturefromresourcew,d3dxcreatetextw,'+
    'd3dxcreatetorus,d3dxcreatevolumetexture,d3dxcreatevolumetexturefromfile,'+
    'd3dxcreatevolumetexturefromfilea,d3dxcreatevolumetexturefromfileex,'+
    'd3dxcreatevolumetexturefromfileexa,d3dxcreatevolumetexturefromfileexw,'+
    'd3dxcreatevolumetexturefromfileinmemory'+
    'd3dxcreatevolumetexturefromfileinmemoryex,d3dxcreatevolumetexturefromfilew,'+
    'd3dxcreatevolumetexturefromresource,d3dxcreatevolumetexturefromresourcea,'+
    'd3dxcreatevolumetexturefromresourceex,d3dxcreatevolumetexturefromresourceexa,'+
    'd3dxcreatevolumetexturefromresourceexw,d3dxcreatevolumetexturefromresourcew,'+
    'd3dxdeclaratorfromfvf,d3dxfillcubetexture,d3dxfilltexture,d3dxfillvolumetexture,'+
    'd3dxfiltertexture,d3dxfresnelterm,d3dxfvffromdeclarator,d3dxgeneratepmesh,'+
    'd3dxgeterrorstring,d3dxgeterrorstringa,d3dxgeterrorstringw,d3dxgetfvfvertexsize,'+
    'd3dxgetimageinfofromfile,d3dxgetimageinfofromfilea,'+
    'd3dxgetimageinfofromfileinmemory,d3dxgetimageinfofromfilew,'+
    'd3dxgetimageinfofromresource,d3dxgetimageinfofromresourcea,'+
    'd3dxgetimageinfofromresourcew,d3dxintersect,d3dxintersectsubset,'+
    'd3dxintersecttri,d3dxloadmeshfromx,d3dxloadmeshfromxof,d3dxloadskinmeshfromxof,'+
    'd3dxloadsurfacefromfile,d3dxloadsurfacefromfilea,'+
    'd3dxloadsurfacefromfileinmemory,d3dxloadsurfacefromfilew,'+
    'd3dxloadsurfacefrommemory,d3dxloadsurfacefromresource,'+
    'd3dxloadsurfacefromresourcea,d3dxloadsurfacefromresourcew,'+
    'd3dxloadsurfacefromsurface,d3dxloadvolumefromfile,d3dxloadvolumefromfilea,'+
    'd3dxloadvolumefromfileinmemory,d3dxloadvolumefromfilew,d3dxloadvolumefrommemory,'+
    'd3dxloadvolumefromresource,d3dxloadvolumefromresourcea,'+
    'd3dxloadvolumefromresourcew,d3dxloadvolumefromvolume,'+
    'd3dxmatrixaffinetransformation,d3dxmatrixfdeterminant,d3dxmatrixinverse,'+
    'd3dxmatrixlookatlh,d3dxmatrixlookatrh,d3dxmatrixmultiply,'+
    'd3dxmatrixmultiplytranspose,d3dxmatrixortholh,d3dxmatrixorthooffcenterlh,'+
    'd3dxmatrixorthooffcenterrh,d3dxmatrixorthorh,d3dxmatrixperspectivefovlh,'+
    'd3dxmatrixperspectivefovrh,d3dxmatrixperspectivelh,'+
    'd3dxmatrixperspectiveoffcenterlh,d3dxmatrixperspectiveoffcenterrh,'+
    'd3dxmatrixperspectiverh,d3dxmatrixreflect,d3dxmatrixrotationaxis,'+
    'd3dxmatrixrotationquaternion,d3dxmatrixrotationx,d3dxmatrixrotationy,'+
    'd3dxmatrixrotationyawpitchroll,d3dxmatrixrotationz,d3dxmatrixscaling,'+
    'd3dxmatrixshadow,d3dxmatrixtransformation,d3dxmatrixtranslation,'+
    'd3dxmatrixtranspose,d3dxplanefrompointnormal,d3dxplanefrompoints,'+
    'd3dxplaneintersectline,d3dxplanenormalize,d3dxplanetransform,'+
    'd3dxquaternionbarycentric,d3dxquaternionexp,d3dxquaternioninverse,'+
    'd3dxquaternionln,d3dxquaternionmultiply,d3dxquaternionnormalize,'+
    'd3dxquaternionrotationaxis,d3dxquaternionrotationmatrix,'+
    'd3dxquaternionrotationyawpitchroll,d3dxquaternionslerp,d3dxquaternionsquad,'+
    'd3dxquaternionsquadsetup,d3dxquaterniontoaxisangle,d3dxsavemeshtox,'+
    'd3dxsavesurfacetofile,d3dxsavesurfacetofilea,d3dxsavesurfacetofilew,'+
    'd3dxsavetexturetofile,d3dxsavetexturetofilea,d3dxsavetexturetofilew,'+
    'd3dxsavevolumetofile,d3dxsavevolumetofilea,d3dxsavevolumetofilew,'+
    'd3dxsimplifymesh,d3dxsphereboundprobe,d3dxsplitmesh,d3dxtessellatenpatches,'+
    'd3dxvalidmesh,d3dxvec2barycentric,d3dxvec2catmullrom,d3dxvec2hermite,'+
    'd3dxvec2normalize,d3dxvec2transform,d3dxvec2transformcoord,'+
    'd3dxvec2transformnormal,d3dxvec3barycentric,d3dxvec3catmullrom,d3dxvec3hermite,'+
    'd3dxvec3normalize,d3dxvec3project,d3dxvec3transform,d3dxvec3transformcoord,'+
    'd3dxvec3transformnormal,d3dxvec3unproject,d3dxvec4barycentric,'+
    'd3dxvec4catmullrom,d3dxvec4cross,d3dxvec4hermite,d3dxvec4normalize,'+
    'd3dxvec4transform,d3dxweldvertices,dad_autoscroll,dad_dragenterex,'+
    'dad_dragenterex2,dad_dragleave,dad_dragmove,dad_setdragimage,dad_showdragimage,'+
    'dateadd,datediff,datedifftotal,datetimetodatestring,datetimetodatestringlong,'+
    'datetimetodatestringshort,datetimetostring,datetimetostringformat,'+
    'datetimetostringlong,datetimetostringlong12,datetimetostringlong24,'+
    'datetimetostringshort,datetimetostringshort12,datetimetostringshort24,'+
    'datetimetotimestring,datetimetotimestring12,datetimetotimestring24,'+
    'datetimetoymdhms,day,daylightsavingtimeenddatetime,'+
    'daylightsavingtimestartdatetime,dayofweek,dayofweekname,dayofyear,daysinmonth,'+
    'dbgbreakpoint,dbgbreakpointwithstatus,dbgcommandstring,dbggetpointers,'+
    'dbginitoss,dbgloadimagesymbols,dbgnotifydebugged,dbgnotifynewtask,'+
    'dbgnotifyremotethreadaddress,dbgprint,dbgprinterrorinfo,dbgprintex,dbgprintf,'+
    'dbgprintreturncontrolc,dbgprompt,dbgquerydebugfilterstate,'+
    'dbgsetdebugfilterstate,dbguiconnecttodbg,dbguicontinue,'+
    'dbguiconvertstatechangestructure,dbguidebugactiveprocess,'+
    'dbguigetthreaddebugobject,dbguiissueremotebreakin,dbguiremotebreakin,'+
    'dbguisetthreaddebugobject,dbguistopdebugging,dbguiwaitstatechange,'+
    'dbguserbreakpoint,dbgwin32heapfail,dbgwin32heapstat,dbtoampfactor,'+
    'dceerrorinqtext,dceerrorinqtexta,dceerrorinqtextw,dcisort,dcomchannelsethresult,'+
    'dcomp_close,dcomp_decompressblock,dcomp_init,dcomp_reset,ddeabandontransaction,'+
    'ddeaccessdata,ddeadddata,ddeclienttransaction,ddecmpstringhandles,ddeconnect,'+
    'ddeconnectlist,ddecreatedatahandle,ddecreatestringhandle,ddecreatestringhandlea,'+
    'ddecreatestringhandlew,ddedisconnect,ddedisconnectlist,ddeenablecallback,'+
    'ddefreedatahandle,ddefreestringhandle,ddegetdata,ddegetlasterror,'+
    'ddeimpersonateclient,ddeinitialize,ddeinitializea,ddeinitializew,'+
    'ddekeepstringhandle,ddenameservice,ddepostadvise,ddequeryconvinfo,'+
    'ddequerynextserver,ddequerystring,ddequerystringa,ddequerystringw,ddereconnect,'+
    'ddesetqualityofservice,ddesetuserhandle,ddeunaccessdata,ddeuninitialize,'+
    'ddgetattachedsurfacelcl,ddinternallock,ddinternalunlock,ddmgetphonebookinfo,'+
    'deactivateactctx,deallocatentmsmedia,debugactiveprocess,debugactiveprocessstop,'+
    'debugbreak,debugbreakprocess,debuggetframelocks,debugprinta,'+
    'debugprintwaitworkerthreads,debugsetprocesskillonexit,debugshowlocks,decode,'+
    'decode_aligned_offset_block,decode_block,decode_data,decode_uncompressed_block,'+
    'decode_verbatim_block,decodeandscale,decodeandscale2,decodeimage,decodepointer,'+
    'decoder_misc_init,decoder_translate_e8,decodesnmpobjectidentifier,'+
    'decodesystempointer,decomment,decommissionntmsmedia,decompresstext,'+
    'decrgb12_8_uv1,decrgb12_8_y1,decrgb12h_8_uv1,decrgb12h_8_y1,decrgb16_8_uv1,'+
    'decrgb16_8_y1,decrgb16v_uv,decrgb16v_y,decrgb24uv1,decrgb24y1,decryptfile,'+
    'decryptfilea,decryptfilew,decryptmessage,defcreate,defcreatefromclip,'+
    'defcreatefromfile,defcreatefromtemplate,defcreateinvisible,'+
    'defcreatelinkfromclip,defcreatelinkfromfile,defdlgproc,defdlgproca,defdlgprocw,'+
    'defdriverproc,deferwindowpos,defframeproc,defframeproca,defframeprocw,'+
    'definedosdevice,definedosdevicea,definedosdevicew,deflate,defloadfromstream,'+
    'defmdichildproc,defmdichildproca,defmdichildprocw,defrawinputproc,'+
    'defsubclassproc,defwindowproc,defwindowproca,defwindowprocw,deinitmapiutil,'+
    'delayloadfailurehook,deleteace,deleteaddress,deleteallgpolinks,deleteatom,'+
    'deleteclientinfo,deleteclustergroup,deleteclusterresource,'+
    'deleteclusterresourcetype,deletecolorspace,deletecolortransform,'+
    'deletecompressor,deletecriticalsection,deletedc,deletedesktopitem,'+
    'deletedesktopitema,deletedesktopitemw,deleteenhmetafile,deleteexpertfromgroup,'+
    'deleteextractedfiles,deletefiber,deletefile,deletefilea,deletefilew,deleteform,'+
    'deleteforma,deleteformw,deleteframe,deletefromtable,deletegpolink,deletegroup,'+
    'deletegroupa,deletegroupw,deletehiliter,deleteie3cache,deleteindex,'+
    'deleteipaddress,deleteipforwardentry,deleteipnetentry,deleteitem,deleteitema,'+
    'deleteitemw,deletelinkfile,deletelinkfilea,deletelinkfilew,deletemenu,'+
    'deletemetafile,deletemonitor,deletemonitora,deletemonitorw,deletentmsdrive,'+
    'deletentmslibrary,deletentmsmedia,deletentmsmediapool,deletentmsmediatype,'+
    'deletentmsrequests,deleteobject,deletepermachineconnection,'+
    'deletepermachineconnectiona,deletepermachineconnectionw,deleteport,deleteporta,'+
    'deleteportw,deleteprinter,deleteprinterconnection,deleteprinterconnectiona,'+
    'deleteprinterconnectionw,deleteprinterdata,deleteprinterdataa,'+
    'deleteprinterdataex,deleteprinterdataexa,deleteprinterdataexw,'+
    'deleteprinterdataw,deleteprinterdriver,deleteprinterdrivera,'+
    'deleteprinterdriverex,deleteprinterdriverexa,deleteprinterdriverexw,'+
    'deleteprinterdriverw,deleteprinteric,deleteprinterkey,deleteprinterkeya,'+
    'deleteprinterkeyw,deleteprintprocessor,deleteprintprocessora,'+
    'deleteprintprocessorw,deleteprintprovidor,deleteprintprovidora,'+
    'deleteprintprovidorw,deleteprofile,deleteprofilea,deleteprofilew,'+
    'deleteproxyarpentry,deletepwrscheme,deletesearcher,deletesecuritycontext,'+
    'deletesecuritypackage,deletesecuritypackagea,deletesecuritypackagew,'+
    'deleteservice,deletesocketport,deletetimerqueue,deletetimerqueueex,'+
    'deletetimerqueuetimer,deleteurlcachecontainer,deleteurlcachecontainera,'+
    'deleteurlcachecontainerw,deleteurlcacheentry,deleteurlcacheentrya,'+
    'deleteurlcacheentryw,deleteurlcachegroup,deleteurlfile,deletevolumemountpoint,'+
    'deletevolumemountpointa,deletevolumemountpointw,delnode,delnoderundll32,'+
    'demclienterrorex,demfiledelete,demfilefindfirst,demfilefindnext,'+
    'demgetcurrentdirectorylcds,demgetfiletimebyhandle_wo,demgetfiletimebyhandle_wow,'+
    'demgetphysicaldrivetype,demisshortpathname,demlfncleanup,'+
    'demlfngetcurrentdirectory,demsetcurrentdirectorygetdrive,'+
    'demsetcurrentdirectorylcds,demwowlfnallocatesearchhandle,'+
    'demwowlfnclosesearchhandle,demwowlfnentry,demwowlfngetsearchhandle,'+
    'demwowlfninit,deregistereventsource,deregisteridleroutine,'+
    'deregisternotification,deregisteropregionhandler,deregisterservice,'+
    'deregisterservicebyusn,deregistershellhookwindow,deregisterwaiteventbinding,'+
    'deregisterwaiteventbindingself,deregisterwaiteventstimers,'+
    'deregisterwaiteventstimersself,describepixelformat,destroyacceleratortable,'+
    'destroyaddressdatabase,destroybatmeter,destroyblob,destroycapture,destroycaret,'+
    'destroycursor,destroyenvironmentblock,destroyfilter,destroyframe,'+
    'destroyhandofftable,destroyicon,destroyinterface,destroymenu,destroynetworkid,'+
    'destroynppblobtable,destroyobjectheap,destroypassword,'+
    'destroyprivateobjectsecurity,destroypropertydatabase,destroypropertysheetpage,'+
    'destroyprotocol,destroytable,destroywindow,detectautoproxyurl,'+
    'determineprofileslocation,devicebayclassinstaller,devicecapabilities,'+
    'devicecapabilitiesa,devicecapabilitiesex,devicecapabilitiesexa,'+
    'devicecapabilitiesexw,devicecapabilitiesw,devicecreatehardwarepage,'+
    'devicecreatehardwarepageex,deviceiocontrol,devicemode,devicepropertysheets,'+
    'devinstall,devinstallw,devqueryprint,devqueryprintex,dg,dgcc,dgep,dgpe,dgpkt,'+
    'dgpkthdr,dgsc,dhcpacquireparameters,dhcpacquireparametersbybroadcast,'+
    'dhcpcapicleanup,dhcpcapiinitialize,dhcpdelpersistentrequestparams,'+
    'dhcpderegisteroptions,dhcpderegisterparamchange,dhcpenumclasses,'+
    'dhcpfallbackrefreshparams,dhcphandlepnpevent,dhcpleaseipaddress,'+
    'dhcpleaseipaddressex,dhcpnotifyconfigchange,dhcpnotifyconfigchangeex,'+
    'dhcpnotifymediareconnected,dhcpopenglobalevent,dhcppersistentrequestparams,'+
    'dhcpqueryhwinfo,dhcpregisteroptions,dhcpregisterparamchange,'+
    'dhcpreleaseipaddresslease,dhcpreleaseipaddressleaseex,dhcpreleaseparameters,'+
    'dhcpremovednsregistrations,dhcprenewipaddresslease,dhcprenewipaddressleaseex,'+
    'dhcprequestoptions,dhcprequestparams,dhcpstaticrefreshparams,'+
    'dhcpundorequestparams,dhdisabledevicehost,dhenabledevicehost,dhseticsinterfaces,'+
    'dhseticsoff,dialogboxindirectparam,dialogboxindirectparama,'+
    'dialogboxindirectparamw,dialogboxparam,dialogboxparama,dialogboxparamw,'+
    'dibchangedata,dibclone,dibcopy,dibdraw,dibenumformat,dibequal,dibgetdata,'+
    'dibquerybounds,dibrelease,dibsavetostream,dict,dict2,diraddentry,dirbind,'+
    'dircompare,direct3dcreate8,directdrawcreate,directdrawcreateclipper,'+
    'directdrawcreateex,directdrawenumerate,directdrawenumeratea,'+
    'directdrawenumerateex,directdrawenumerateexa,directdrawenumerateexw,'+
    'directdrawenumeratew,directinput8create,directinputcreate,directinputcreatea,'+
    'directinputcreateex,directinputcreatew,directplaycreate,directplayenumerate,'+
    'directplayenumeratea,directplayenumeratew,directplaylobbycreate,'+
    'directplaylobbycreatea,directplaylobbycreatew,directsoundcapturecreate,'+
    'directsoundcapturecreate8,directsoundcaptureenumerate,'+
    'directsoundcaptureenumeratea,directsoundcaptureenumeratew,directsoundcreate,'+
    'directsoundcreate8,directsoundenumerate,directsoundenumeratea,'+
    'directsoundenumeratew,directsoundfullduplexcreate,directxdevicedriversetup,'+
    'directxdevicedriversetupa,directxdevicedriversetupw,directxfilecreate,'+
    'directxloadstring,directxregisterapplication,directxregisterapplicationa,'+
    'directxregisterapplicationw,directxsetup,directxsetupa,directxsetupcallback,'+
    'directxsetupgetfileversion,directxsetupgetversion,directxsetupiseng,'+
    'directxsetupisjapan,directxsetupisjapannec,directxsetupsetcallback,'+
    'directxsetupshoweula,directxsetupw,directxunregisterapplication,'+
    'direrrortontstatus,direrrortowinerror,dirfindentry,dirgetdomainhandle,dirlist,'+
    'dirmodifydn,dirmodifyentry,dirnotifyregister,dirnotifyunregister,'+
    'diroperationcontrol,dirprepareforimpersonate,dirprotectentry,dirread,'+
    'dirremoveentry,dirreplicaadd,dirreplicadelete,dirreplicademote,'+
    'dirreplicagetdemotetarget,dirreplicamodify,dirreplicareferenceupdate,'+
    'dirreplicasetcredentials,dirreplicasynchronize,dirsearch,dirstopimpersonating,'+
    'dirtransactcontrol,dirunbind,disable_procs,disablefifo,disablemediasense,'+
    'disablentmsobject,disableparserfilter,disableprocesswindowsghosting,'+
    'disableprotocol,disablesr,disablethreadlibrarycalls,'+
    'disassociatecolorprofilefromdevice,disassociatecolorprofilefromdevicea,'+
    'disassociatecolorprofilefromdevicew,discardindex,discdlgstruct,'+
    'disconnectnamedpipe,diskproppageprovider,dismountntmsdrive,dismountntmsmedia,'+
    'dispatchinterrupts,dispatchmessage,dispatchmessagea,dispatchmessagew,'+
    'dispcallfunc,dispgetidsofnames,dispgetparam,dispinvoke,display_device,'+
    'displaybmp,displayicon,displayoptions,dispmangetcontext,dissort,ditherto8,'+
    'dlccalldriver,dlgdirlist,dlgdirlista,dlgdirlistcombobox,dlgdirlistcomboboxa,'+
    'dlgdirlistcomboboxw,dlgdirlistw,dlgdirselectcomboboxex,dlgdirselectcomboboxexa,'+
    'dlgdirselectcomboboxexw,dlgdirselectex,dlgdirselectexa,dlgdirselectexw,'+
    'dllallocsplmem,dllbidentrypoint,dllcreate,dllcreatefromclip,dllcreatefromfile,'+
    'dllcreatefromtemplate,dllcreatelinkfromclip,dllcreatelinkfromfile,'+
    'dlldebugobjectrpchook,dllentrypoint,dllfreesplmem,dllfreesplstr,'+
    'dllgetclassobjectwo,dllgetclassobjectwow,dllgetversion,dllloadfromstream,'+
    'dllmain,dllunload,dllunregisterserverwereallymeanit,dmoenum,dmogetname,'+
    'dmogettypes,dmoguidtostr,dmoguidtostra,dmoguidtostrw,dmoregister,dmostrtoguid,'+
    'dmostrtoguida,dmostrtoguidw,dmounregister,dn_expand,dns_addrecordstomessage,'+
    'dns_allocatemsgbuf,dns_buildpacket,dns_cachesocketcleanup,dns_cachesocketinit,'+
    'dns_cleanupwinsock,dns_closeconnection,dns_closehostfile,dns_closesocket,'+
    'dns_createmulticastsocket,dns_createsocket,dns_createsocketex,'+
    'dns_findauthoritativezonelib,dns_getipaddresses,dns_getlocalipaddressarray,'+
    'dns_getrandomxid,dns_initializemsgremotesockaddr,dns_initializewinsock,'+
    'dns_initquerytimeouts,dns_openhostfile,dns_opentcpconnectionandsend,'+
    'dns_parsemessage,dns_parsepacketrecord,dns_pingadapterservers,'+
    'dns_readhostfileline,dns_readrecordstructurefrompacket,dns_recvtcp,'+
    'dns_resetnetworkinfo,dns_sendandrecvudp,dns_sendex,dns_setrecorddatalength,'+
    'dns_skiptorecord,dns_updatelib,dns_updatelibex,dns_writequestiontomessage,'+
    'dns_writerecordstructuretopacketex,dnsacquirecontexthandle_,'+
    'dnsacquirecontexthandle_a,dnsacquirecontexthandle_w,dnsaddrecordset_,'+
    'dnsaddrecordset_a,dnsaddrecordset_utf8,dnsaddrecordset_w,dnsallocaterecord,'+
    'dnsapialloc,dnsapifree,dnsapiheapreset,dnsapirealloc,dnsapisetdebugglobals,'+
    'dnsasyncregisterhostaddrs,dnsasyncregisterinit,dnsasyncregisterterm,'+
    'dnscopystringex,dnscreatereversenamestringforipaddress,'+
    'dnscreatestandarddnsnamecopy,dnscreatestringcopy,dnsdhcpsrvregisterhostname,'+
    'dnsdhcpsrvregisterinit,dnsdhcpsrvregisterinitialize,dnsdhcpsrvregisterterm,'+
    'dnsdowncasednsnamelabel,dnsextractrecordsfrommessage_,'+
    'dnsextractrecordsfrommessage_utf8,dnsextractrecordsfrommessage_w,'+
    'dnsfindauthoritativezone,dnsflushresolvercache,dnsflushresolvercacheentry_,'+
    'dnsflushresolvercacheentry_a,dnsflushresolvercacheentry_utf8,'+
    'dnsflushresolvercacheentry_w,dnsfree,dnsfreeconfigstructure,'+
    'dnsgetbufferlengthforstringcopy,dnsgetcachedatatable,dnsgetdnsserverlist,'+
    'dnsgetipaddressinfolist,dnsgetlastfailedupdateinfo,dnsgetlocaladdrarray,'+
    'dnsgetlocaladdrarraydirect,dnsgetprimarydomainname_a,dnsglobals,'+
    'dnshostnametocomputername,dnshostnametocomputernamea,dnshostnametocomputernamew,'+
    'dnsipv6addresstostring,dnsipv6stringtoaddress,dnsisstringcountvalidfortexttype,'+
    'dnsmodifyrecordset_,dnsmodifyrecordset_a,dnsmodifyrecordset_utf8,'+
    'dnsmodifyrecordset_w,dnsmodifyrecordsinset_,dnsmodifyrecordsinset_a,'+
    'dnsmodifyrecordsinset_utf8,dnsmodifyrecordsinset_w,dnsnamecompare_,'+
    'dnsnamecompare_a,dnsnamecompare_utf8,dnsnamecompare_w,dnsnamecompareex_,'+
    'dnsnamecompareex_a,dnsnamecompareex_utf8,dnsnamecompareex_w,dnsnamecopy,'+
    'dnsnamecopyallocate,dnsnotifyresolver,dnsnotifyresolverclusterip,'+
    'dnsnotifyresolverex,dnsquery_,dnsquery_a,dnsquery_utf8,dnsquery_w,'+
    'dnsqueryconfig,dnsqueryconfigallocex,dnsqueryconfigdword,dnsqueryex,dnsqueryexa,'+
    'dnsqueryexutf8,dnsqueryexw,dnsrecordbuild_,dnsrecordbuild_utf8,dnsrecordbuild_w,'+
    'dnsrecordcompare,dnsrecordcopyex,dnsrecordlistfree,dnsrecordsetcompare,'+
    'dnsrecordsetcopyex,dnsrecordsetdetach,dnsrecordstringfortype,'+
    'dnsrecordstringforwritabletype,dnsrecordtypeforname,dnsregisterclusteraddress,'+
    'dnsreleasecontexthandle,dnsremoveregistrations,dnsreplacerecordset,'+
    'dnsreplacerecordseta,dnsreplacerecordsetutf8,dnsreplacerecordsetw,'+
    'dnssetconfigdword,dnsstringcopyallocateex,dnsupdate,dnsupdatetest_,'+
    'dnsupdatetest_a,dnsupdatetest_utf8,dnsupdatetest_w,dnsvalidatename_,'+
    'dnsvalidatename_a,dnsvalidatename_utf8,dnsvalidatename_w,dnsvalidateutf8byte,'+
    'dnswritequestiontobuffer_,dnswritequestiontobuffer_utf8,'+
    'dnswritequestiontobuffer_w,dnswritereversenamestringforipaddress,'+
    'do_block_output,do_echo_rep,do_echo_req,docabinetinfonotify,docmd,'+
    'doconnectoidsexist,documentevent,documentproperties,documentpropertiesa,'+
    'documentpropertiesw,documentpropertysheets,docwndproc,dodragdrop,'+
    'doejectfromsadrive,doejectfromsadrivew,doenvironmentsubst,doenvironmentsubsta,'+
    'doenvironmentsubstw,doinfinstall,doinstallcomponentinfs,dologevent,'+
    'dologeventandtrace,dologoverride,doneciisapiperformancedata,'+
    'doneciperformancedata,donefilterperformancedata,dorequest,dos_flag_addr,'+
    'dosdatetimetofiletime,dosdatetimetovarianttime,dospathtosessionpath,'+
    'dospathtosessionpatha,dospathtosessionpathw,downheap,downloadfile,'+
    'dpa_deleteallptrs,dpa_deleteptr,dpa_destroycallback,dpa_enumcallback,'+
    'dpa_insertptr,dpa_search,dpa_setptr,dpa_sort,dpmisetincrementalalloc,dptolp,'+
    'dpws_buildipmessageheader,dpws_getenumport,dragacceptfiles,dragdetect,'+
    'dragfinish,draginfo,dragobject,dragqueryfile,dragqueryfilea,dragqueryfileaor,'+
    'dragqueryfileaorw,dragqueryfilew,dragquerypoint,drawanimatedrects,drawcaption,'+
    'drawdibbegin,drawdibchangepalette,drawdibclose,drawdibdraw,drawdibend,'+
    'drawdibgetbuffer,drawdibgetpalette,drawdibopen,drawdibprofiledisplay,'+
    'drawdibrealize,drawdibsetpalette,drawdibstart,drawdibstop,drawdibtime,drawedge,'+
    'drawescape,drawfocusrect,drawframe,drawframecontrol,drawicon,drawiconex,'+
    'drawinsert,drawmenubar,drawshadowtext,drawstate,drawstatea,drawstatew,'+
    'drawstatustext,drawstatustexta,drawstatustextw,drawtext,drawtexta,drawtextex,'+
    'drawtextexa,drawtextexw,drawtextw,drawthemebackground,drawthemebackgroundex,'+
    'drawthemeedge,drawthemeicon,drawthemeparentbackground,drawthemetext,'+
    'drivercallback,drivercleanuppolicy,driverfinalpolicy,driverinitializepolicy,'+
    'drivetype,drmaddcontenthandlers,drmcreatecontentmixed,drmdestroycontent,'+
    'drmforwardcontenttodeviceobject,drmforwardcontenttofileobject,'+
    'drmforwardcontenttointerface,drmgetcontentrights,drmgetfilterdescriptor,'+
    'drvgetmodulehandle,dsa_create,dsa_destroy,dsa_destroycallback,dsa_getitemptr,'+
    'dsa_insertitem,dsaddresstositenames,dsaddresstositenamesa,'+
    'dsaddresstositenamesex,dsaddresstositenamesexa,dsaddresstositenamesexw,'+
    'dsaddresstositenamesw,dsaddsidhistory,dsaddsidhistorya,dsaddsidhistoryw,'+
    'dsadisableupdates,dsaenableupdates,dsaexestartroutine,dsaopbind,'+
    'dsaopbindwithcred,dsaopbindwithspn,dsaopexecutescript,dsaoppreparescript,'+
    'dsaopunbind,dsasetinstallcallback,dsawaituntilserviceisrunning,dsbackupclose,'+
    'dsbackupend,dsbackupfree,dsbackupgetbackuplogs,dsbackupgetbackuplogsa,'+
    'dsbackupgetbackuplogsw,dsbackupgetdatabasenames,dsbackupgetdatabasenamesa,'+
    'dsbackupgetdatabasenamesw,dsbackupopenfile,dsbackupopenfilea,dsbackupopenfilew,'+
    'dsbackupprepare,dsbackuppreparea,dsbackuppreparew,dsbackupread,'+
    'dsbackuptruncatelogs,dsbind,dsbinda,dsbindw,dsbindwithcred,dsbindwithcreda,'+
    'dsbindwithcredw,dsbindwithspn,dsbindwithspna,dsbindwithspnw,'+
    'dsbrowseforcontainer,dsbrowseforcontainera,dsbrowseforcontainerw,'+
    'dschangebootoptions,dscheckconstraint,dsclientmakespnfortargetserver,'+
    'dsclientmakespnfortargetservera,dsclientmakespnfortargetserverw,dscracknames,'+
    'dscracknamesa,dscracknamesw,dscrackspn,dscrackspn2,dscrackspn2a,dscrackspn2w,'+
    'dscrackspn3,dscrackspn3w,dscrackspna,dscrackspnw,dscrackunquotedmangledrdn,'+
    'dscrackunquotedmangledrdna,dscrackunquotedmangledrdnw,'+
    'dscreateisecurityinfoobject,dscreateisecurityinfoobjectex,dscreatesecuritypage,'+
    'dsderegisterdnshostrecords,dsderegisterdnshostrecordsa,'+
    'dsderegisterdnshostrecordsw,dseditsecurity,dsenumeratedomaintrusts,'+
    'dsenumeratedomaintrustsa,dsenumeratedomaintrustsw,dsfreedomaincontrollerinfo,'+
    'dsfreedomaincontrollerinfoa,dsfreedomaincontrollerinfow,dsfreenameresult,'+
    'dsfreenameresulta,dsfreenameresultw,dsfreepasswordcredentials,'+
    'dsfreeschemaguidmap,dsfreeschemaguidmapa,dsfreeschemaguidmapw,'+
    'dsfreeserversandsitesfornetlogon,dsfreespnarray,dsfreespnarraya,dsfreespnarrayw,'+
    'dsgetbootoptions,dsgetdcclose,dsgetdcclosew,dsgetdcname,dsgetdcnamea,'+
    'dsgetdcnamew,dsgetdcnamewithaccount,dsgetdcnamewithaccounta,'+
    'dsgetdcnamewithaccountw,dsgetdcnext,dsgetdcnexta,dsgetdcnextw,dsgetdcopen,'+
    'dsgetdcopena,dsgetdcopenw,dsgetdcsitecoverage,dsgetdcsitecoveragea,'+
    'dsgetdcsitecoveragew,dsgetdefaultobjcategory,dsgetdomaincontrollerinfo,'+
    'dsgetdomaincontrollerinfoa,dsgetdomaincontrollerinfow,dsgeteventconfig,'+
    'dsgetforesttrustinformation,dsgetforesttrustinformationw,dsgetfriendlyclassname,'+
    'dsgeticon,dsgetrdn,dsgetrdnw,dsgetserversandsitesfornetlogon,dsgetsitename,'+
    'dsgetsitenamea,dsgetsitenamew,dsgetspn,dsgetspna,dsgetspnw,'+
    'dsinheritsecurityidentity,dsinheritsecurityidentitya,dsinheritsecurityidentityw,'+
    'dsinitialize,dsinitializecritsecs,dsisbeingbacksynced,dsismangleddn,'+
    'dsismangleddna,dsismangleddnw,dsismangledrdnvalue,dsismangledrdnvaluea,'+
    'dsismangledrdnvaluew,dsisntdsonline,dsisntdsonlinea,dsisntdsonlinew,'+
    'dslistdomainsinsite,dslistdomainsinsitea,dslistdomainsinsitew,'+
    'dslistinfoforserver,dslistinfoforservera,dslistinfoforserverw,dslistroles,'+
    'dslistrolesa,dslistrolesw,dslistserversfordomaininsite,'+
    'dslistserversfordomaininsitea,dslistserversfordomaininsitew,dslistserversinsite,'+
    'dslistserversinsitea,dslistserversinsitew,dslistsites,dslistsitesa,dslistsitesw,'+
    'dslogentry,dsm_entry,dsmakepasswordcredentials,dsmakepasswordcredentialsa,'+
    'dsmakepasswordcredentialsw,dsmakespn,dsmakespna,dsmakespnw,dsmapschemaguids,'+
    'dsmapschemaguidsa,dsmapschemaguidsw,dsmergeforesttrustinformation,'+
    'dsmergeforesttrustinformationw,dsnametohashkeyexternal,'+
    'dsnametomappedstrexternal,dsoundhelp,dsqsort,dsquoterdnvalue,dsquoterdnvaluea,'+
    'dsquoterdnvaluew,dsremovedsdomain,dsremovedsdomaina,dsremovedsdomainw,'+
    'dsremovedsserver,dsremovedsservera,dsremovedsserverw,dsreplicaadd,dsreplicaadda,'+
    'dsreplicaaddw,dsreplicaconsistencycheck,dsreplicadel,dsreplicadela,'+
    'dsreplicadelw,dsreplicafreeinfo,dsreplicagetinfo,dsreplicagetinfo2,'+
    'dsreplicagetinfo2w,dsreplicagetinfow,dsreplicamodify,dsreplicamodifya,'+
    'dsreplicamodifyw,dsreplicasync,dsreplicasynca,dsreplicasyncall,'+
    'dsreplicasyncalla,dsreplicasyncallw,dsreplicasyncw,dsreplicaupdaterefs,'+
    'dsreplicaupdaterefsa,dsreplicaupdaterefsw,dsreplicaverifyobjects,'+
    'dsreplicaverifyobjectsa,dsreplicaverifyobjectsw,dsrestorecheckexpirytoken,'+
    'dsrestoreend,dsrestoregetdatabaselocations,dsrestoregetdatabaselocationsa,'+
    'dsrestoregetdatabaselocationsw,dsrestoreprepare,dsrestorepreparea,'+
    'dsrestorepreparew,dsrestoreregister,dsrestoreregistera,'+
    'dsrestoreregistercomplete,dsrestoreregisterw,dsroleabortdownlevelserverupgrade,'+
    'dsrolecancel,dsroledcasdc,dsroledcasreplica,dsroledemotedc,'+
    'dsrolednsnametoflatname,dsrolefreememory,dsrolegetdatabasefacts,'+
    'dsrolegetdcoperationprogress,dsrolegetdcoperationresults,'+
    'dsrolegetprimarydomaininformation,dsrolerdcasdc,dsrolerdcasreplica,'+
    'dsrolerdemotedc,dsrolergetdcoperationprogress,dsrolergetdcoperationresults,'+
    'dsroleserversavestateforupgrade,dsroleupgradedownlevelserver,'+
    'dsserverregisterspn,dsserverregisterspna,dsserverregisterspnw,dssetauthidentity,'+
    'dssetauthidentitya,dssetauthidentityw,dssetcurrentbackuplog,'+
    'dssetcurrentbackuploga,dssetcurrentbackuplogw,dssort,dsstrtohashkeyexternal,'+
    'dsstrtomappedstrexternal,dstraceevent,dsunbind,dsunbinda,dsunbindw,'+
    'dsuninitialize,dsunquoterdnvalue,dsunquoterdnvaluea,dsunquoterdnvaluew,'+
    'dsvalidatesubnetname,dsvalidatesubnetnamea,dsvalidatesubnetnamew,'+
    'dswaituntildelayedstartupisdone,dswriteaccountspn,dswriteaccountspna,'+
    'dswriteaccountspnw,dtcgettransactionmanagerc,dtcgettransactionmanagerexa,'+
    'dummyentrypoint,dumptable,dup2,dupb,duplicateblob,duplicateconsolehandle,'+
    'duplicateencryptioninfofile,duplicatehandle,duplicateicon,duplicatetoken,'+
    'duplicatetokenex,dupmsg,dw2a,dw2bin_ex,dw2hex,dw2hex_ex,dwcloneentry,'+
    'dwdeletesubentry,dwenumentriesforallusers,dwenumentrydetails,dwlbsubclass,'+
    'dwoksubclass,dword_flag_to_string,dwordtobinary,dwrasrefreshkerbsccreds,'+
    'dwrasuninitialize,dwterminaldlg,dwtoa,dxapi,dxapigetversion,dxapiinitialize,'+
    'dxautoflipupdate,dxenableirq,dxloseobject,dxupdatecapture,editsecurity,'+
    'editstreamclone,editstreamcopy,editstreamcut,editstreampaste,editstreamsetinfo,'+
    'editstreamsetinfoa,editstreamsetinfow,editstreamsetname,editstreamsetnamea,'+
    'editstreamsetnamew,editwndproc,eeinfo,eerecord,efsdecryptfek,efsgeneratekey,'+
    'eisauphalcoinstaller,eisauphalproppageprovider,ejectdiskfromsadrive,'+
    'ejectdiskfromsadrivea,ejectdiskfromsadrivew,ejectntmscleaner,ejectntmsmedia,'+
    'elfbackupeventlogfile,elfbackupeventlogfilea,elfbackupeventlogfilew,'+
    'elfchangenotify,elfcleareventlogfile,elfcleareventlogfilea,'+
    'elfcleareventlogfilew,elfcloseeventlog,elfderegistereventsource,'+
    'elfflusheventlog,elfnumberofrecords,elfoldestrecord,elfopenbackupeventlog,'+
    'elfopenbackupeventloga,elfopenbackupeventlogw,elfopeneventlog,elfopeneventloga,'+
    'elfopeneventlogw,elfreadeventlog,elfreadeventloga,elfreadeventlogw,'+
    'elfregistereventsource,elfregistereventsourcea,elfregistereventsourcew,'+
    'elfreportevent,elfreporteventa,elfreporteventw,ellipse,emptyaddressdatabase,'+
    'emptyclipboard,emptyworkingset,enable_procs,enableeudc,enablefifo,'+
    'enablehookobject,enableidleroutine,enablemenuitem,enablentmsobject,enableok,'+
    'enableparserfilter,enableprotocol,enablerouter,enablescrollbar,enablesr,'+
    'enablesrex,enablethemedialogtexture,enabletheming,enabletrace,enablewindow,'+
    'encode_aligned_block,encode_aligned_tree,encode_trees,encode_uncompressed_block,'+
    'encode_verbatim_block,encodeid,encodepointer,encoder_start,encoder_translate_e8,'+
    'encodesnmpobjectidentifier,encodesystempointer,encryptedfilekeyinfo,encryptfile,'+
    'encryptfilea,encryptfilew,encryptiondisable,encryptmessage,endcachetransaction,'+
    'enddeferwindowpos,enddialog,enddoc,enddocport,enddocprinter,endformpage,endmenu,'+
    'endntmsdevicechangedetection,endpage,endpageprinter,endpaint,endpath,endtask,'+
    'endupdateresource,endupdateresourcea,endupdateresourcew,engacquiresemaphore,'+
    'engallocmem,engallocprivateusermem,engallocsectionmem,engallocusermem,'+
    'engalphablend,engassociatesurface,engbitblt,engbugcheckex,engcheckabort,'+
    'engclearevent,engcomputeglyphset,engcontrolsprites,engcopybits,engcreatebitmap,'+
    'engcreateclip,engcreatedevicebitmap,engcreatedevicesurface,engcreatedriverobj,'+
    'engcreateevent,engcreatepalette,engcreatepath,engcreatesemaphore,engcreatewnd,'+
    'engdebugbreak,engdebugprint,engdeleteclip,engdeletedriverobj,engdeleteevent,'+
    'engdeletefile,engdeletepalette,engdeletepath,engdeletesafesemaphore,'+
    'engdeletesemaphore,engdeletesurface,engdeletewnd,engdeviceiocontrol,'+
    'engdithercolor,engdxioctl,engenumforms,engerasesurface,engfileiocontrol,'+
    'engfilewrite,engfillpath,engfindimageprocaddress,engfindresource,'+
    'engfntcachealloc,engfntcachefault,engfntcachelookup,engfreemem,engfreemodule,'+
    'engfreeprivateusermem,engfreesectionmem,engfreeusermem,enggetcurrentcodepage,'+
    'enggetcurrentprocessid,enggetcurrentthreadid,enggetdrivername,'+
    'enggetfilechangetime,enggetfilepath,enggetform,enggetlasterror,enggetprinter,'+
    'enggetprinterdata,enggetprinterdatafilename,enggetprinterdriver,'+
    'enggetprocesshandle,enggettickcount,enggettype1fontlist,enggradientfill,'+
    'enghangnotification,enginitializesafesemaphore,engissemaphoreowned,'+
    'engissemaphoreownedbycurrentthread,englineto,engloadimage,engloadmodule,'+
    'engloadmoduleforwrite,englockdirectdrawsurface,englockdriverobj,englocksurface,'+
    'englpkinstalled,engmapevent,engmapfile,engmapfontfile,engmapfontfilefd,'+
    'engmapmodule,engmapsection,engmarkbandingsurface,engmodifysurface,'+
    'engmovepointer,engmuldiv,engmultibytetounicoden,engmultibytetowidechar,'+
    'engninegrid,engpaint,engplgblt,engprobeforread,engprobeforreadandwrite,'+
    'engquerydeviceattribute,engqueryemfinfo,engquerylocaltime,engquerypalette,'+
    'engqueryperformancecounter,engqueryperformancefrequency,engquerysystemattribute,'+
    'engreadstateevent,engreleasesemaphore,engrestorefloatingpointstate,'+
    'engsavefloatingpointstate,engsecuremem,engsetevent,engsetlasterror,'+
    'engsetpointershape,engsetpointertag,engsetprinterdata,engsort,engstretchblt,'+
    'engstretchbltrop,engstrokeandfillpath,engstrokepath,engtextout,'+
    'engtransparentblt,engunicodetomultibyten,engunloadimage,'+
    'engunlockdirectdrawsurface,engunlockdriverobj,engunlocksurface,engunmapevent,'+
    'engunmapfile,engunmapfontfile,engunmapfontfilefd,engunsecuremem,'+
    'engwaitforsingleobject,engwidechartomultibyte,engwriteprinter,'+
    'enrollmentcomobjectfactory_getinstance,entercriticalpolicysection,'+
    'entercriticalsection,enteruserprofilelock,entryfunc,enum_service_status,'+
    'enumaddresses,enumcalendarinfo,enumcalendarinfoa,enumcalendarinfoex,'+
    'enumcalendarinfoexa,enumcalendarinfoexw,enumcalendarinfow,enumchildwindows,'+
    'enumclipboardformats,enumcolorprofiles,enumcolorprofilesa,enumcolorprofilesw,'+
    'enumdateformats,enumdateformatsa,enumdateformatsex,enumdateformatsexa,'+
    'enumdateformatsexw,enumdateformatsw,enumdependentservices,'+
    'enumdependentservicesa,enumdependentservicesw,enumdesktops,enumdesktopsa,'+
    'enumdesktopsw,enumdesktopwindows,enumdevicedrivers,enumdisplaydevices,'+
    'enumdisplaydevicesa,enumdisplaydevicesw,enumdisplaymonitors,enumdisplaysettings,'+
    'enumdisplaysettingsa,enumdisplaysettingsex,enumdisplaysettingsexa,'+
    'enumdisplaysettingsexw,enumdisplaysettingsw,enumenhmetafile,'+
    'enumerateloadedmodules,enumerateloadedmodules64,enumeratelocalcomputernames,'+
    'enumeratelocalcomputernamesa,enumeratelocalcomputernamesw,enumeratentmsobject,'+
    'enumeratesecuritypackages,enumeratesecuritypackagesa,enumeratesecuritypackagesw,'+
    'enumeratetraceguids,enumexperthandles,enumexpertinfos,enumfontfamilies,'+
    'enumfontfamiliesa,enumfontfamiliesex,enumfontfamiliesexa,enumfontfamiliesexw,'+
    'enumfontfamiliesw,enumfonts,enumfontsa,enumfontsw,enumforms,enumformsa,'+
    'enumformsw,enumforterminate,enumgroups,enumicmprofiles,enumicmprofilesa,'+
    'enumicmprofilesw,enumjobs,enumjobsa,enumjobsw,enumlanguagegrouplocales,'+
    'enumlanguagegrouplocalesa,enumlanguagegrouplocalesw,enummetafile,enummonitors,'+
    'enummonitorsa,enummonitorsw,enummrulist,enummrulistw,enumnetworks,enumobjects,'+
    'enumovertable,enumpagefiles,enumpagefilesa,enumpagefilesw,'+
    'enumpermachineconnections,enumpermachineconnectionsa,enumpermachineconnectionsw,'+
    'enumports,enumportsa,enumportsw,enumprinterdata,enumprinterdataa,'+
    'enumprinterdataex,enumprinterdataexa,enumprinterdataexw,enumprinterdataw,'+
    'enumprinterdrivers,enumprinterdriversa,enumprinterdriversw,enumprinterkey,'+
    'enumprinterkeya,enumprinterkeyw,enumprinterpropertysheets,enumprinters,'+
    'enumprintersa,enumprintersw,enumprintprocessordatatypes,'+
    'enumprintprocessordatatypesa,enumprintprocessordatatypesw,enumprintprocessors,'+
    'enumprintprocessorsa,enumprintprocessorsw,enumprocesses,enumprocessmodules,'+
    'enumprops,enumpropsa,enumpropsex,enumpropsexa,enumpropsexw,enumpropsw,'+
    'enumprotocols,enumprotocolsa,enumprotocolsw,enumpwrschemes,'+
    'enumresourcelanguages,enumresourcelanguagesa,enumresourcelanguagesw,'+
    'enumresourcenames,enumresourcenamesa,enumresourcenamesw,enumresourcetypes,'+
    'enumresourcetypesa,enumresourcetypesw,enumservicegroup,enumservicegroupw,'+
    'enumservicesstatus,enumservicesstatusa,enumservicesstatusex,'+
    'enumservicesstatusexa,enumservicesstatusexw,enumservicesstatusw,'+
    'enumsystemcodepages,enumsystemcodepagesa,enumsystemcodepagesw,enumsystemgeoid,'+
    'enumsystemlanguagegroups,enumsystemlanguagegroupsa,enumsystemlanguagegroupsw,'+
    'enumsystemlocales,enumsystemlocalesa,enumsystemlocalesw,enumthreadwindows,'+
    'enumtimeformats,enumtimeformatsa,enumtimeformatsw,enumuilanguages,'+
    'enumuilanguagesa,enumuilanguagesw,enumuserbrowserselection,enumwindows,'+
    'enumwindowstations,enumwindowstationsa,enumwindowstationsw,equaldomainsid,'+
    'equalprefixsid,equalrect,equalrgn,equalsid,erasetape,erfsetcodes,erractivate,'+
    'errclose,errcopyfromlink,errexecute,errgetupdateoptions,errobjectconvert,'+
    'errobjectlong,error,errqueryopen,errqueryoutofdate,errqueryprotocol,'+
    'errreconnect,errsetbounds,errsetdata,errsethostnames,errsettargetdevice,'+
    'errsetupdateoptions,errshow,errupdate,esballoc,esbbcall,escape,'+
    'escapecommfunction,ese,estimate_buffer_contents,estimate_compressed_block_size,'+
    'ethfilterdprindicatereceive,ethfilterdprindicatereceivecomplete,eudcloadlink,'+
    'eudcloadlinkw,eudcunloadlink,eudcunloadlinkw,eventguidtoname,eventnamefree,'+
    'evictclusternode,evictclusternodeex,exacquireresourceexclusivelite,'+
    'exacquireresourcesharedlite,exacquiresharedstarveexclusive,'+
    'exacquiresharedwaitforexclusive,exallocatecacheawarerundownprotection,'+
    'exallocatefrompagedlookasidelist,exallocatepool,exallocatepoolwithquota,'+
    'exallocatepoolwithquotatag,exallocatepoolwithtag,exallocatepoolwithtagpriority,'+
    'excludecliprect,excludeupdatergn,exconvertexclusivetosharedlite,'+
    'excreatecallback,exdeletenpagedlookasidelist,exdeletepagedlookasidelist,'+
    'exdeleteresourcelite,exdesktopobjecttype,exdisableresourceboostlite,execl,'+
    'execle,execlp,executecab,execv,execve,execvp,'+
    'exentercriticalregionandacquireresourceexclusive'+
    'exentercriticalregionandacquireresourceshared'+
    'exentercriticalregionandacquiresharedwaitforexclusive,exenumhandletable,'+
    'exeventobjecttype,exextendzone,exfreecacheawarerundownprotection,exfreepool,'+
    'exfreepoolwithtag,exfreetopagedlookasidelist,exgetcurrentprocessorcounts,'+
    'exgetcurrentprocessorcpuusage,exgetexclusivewaitercount,exgetpreviousmode,'+
    'exgetsharedwaitercount,exi386interlockeddecrementlong,'+
    'exi386interlockedexchangeulong,exi386interlockedincrementlong,'+
    'exinitializenpagedlookasidelist,exinitializepagedlookasidelist,'+
    'exinitializeresourcelite,exinitializerundownprotectioncacheaware,'+
    'exinitializezone,exinterlockedaddlargeinteger,exinterlockedaddulong,'+
    'exinterlockeddecrementlong,exinterlockedexchangeulong,exinterlockedextendzone,'+
    'exinterlockedincrementlong,exinterlockedinsertheadlist,'+
    'exinterlockedinserttaillist,exinterlockedpopentrylist,'+
    'exinterlockedpushentrylist,exinterlockedremoveheadlist,'+
    'exisprocessorfeaturepresent,exisresourceacquiredexclusivelite,'+
    'exisresourceacquiredsharedlite,exist,existw,exitprocess,exitthread,exitvdm,'+
    'exitwindowsex,exlocaltimetosystemtime,exnotifycallback,expandenvironmentstrings,'+
    'expandenvironmentstringsa,expandenvironmentstringsforuser,'+
    'expandenvironmentstringsforusera,expandenvironmentstringsforuserw,'+
    'expandenvironmentstringsw,expertallocmemory,expertfreememory,expertgetframe,'+
    'expertgetstartupinfo,expertindicatestatus,expertmemorysize,expertreallocmemory,'+
    'expertsubmitevent,expldt,exportcookiefile,exportcookiefilea,exportcookiefilew,'+
    'exportntmsdatabase,exportrsopdata,exportsecuritycontext,'+
    'expungeconsolecommandhistory,expungeconsolecommandhistorya,'+
    'expungeconsolecommandhistoryw,exquerypoolblocksize,exqueueworkitem,'+
    'exraiseaccessviolation,exraisedatatypemisalignment,exraiseexception,'+
    'exraiseharderror,exraisestatus,exregistercallback,exreinitializeresourcelite,'+
    'exreleaseresourceforthreadlite,exsemaphoreobjecttype,exsetresourceownerpointer,'+
    'exsettimerresolution,exsizeofrundownprotectioncacheaware,'+
    'exsystemexceptionfilter,exsystemtimetolocaltime,extcreatepen,extcreateregion,'+
    'extdevicemode,extendvirtualbuffer,extensionpropsheetpageproc,extescape,'+
    'extfloodfill,extract,extractassociatedicon,extractassociatedicona,'+
    'extractassociatediconex,extractassociatediconexa,extractassociatediconexw,'+
    'extractassociatediconw,extractfiles,extracticon,extracticona,extracticonex,'+
    'extracticonexa,extracticonexw,extracticonresinfo,extracticonresinfoa,'+
    'extracticonresinfow,extracticonw,extractversionresource16,'+
    'extractversionresource16w,extselectcliprgn,exttextout,exttextouta,exttextoutw,'+
    'exunregistercallback,exuuidcreate,exverifysuite,exwindowstationobjecttype,'+
    'failclusterresource,fast_decode_aligned_offset_block,fast_decode_verbatim_block,'+
    'fastcopyframe,fatalappexit,fatalappexita,fatalappexitw,fatalexit,'+
    'faultiniefeature,faxabort,faxaccesscheck,faxclose,faxcompletejobparams,'+
    'faxcompletejobparamsa,faxcompletejobparamsw,faxconnectfaxserver,'+
    'faxconnectfaxservera,faxconnectfaxserverw,faxenableroutingmethod,'+
    'faxenableroutingmethoda,faxenableroutingmethodw,faxenumglobalroutinginfo,'+
    'faxenumglobalroutinginfoa,faxenumglobalroutinginfow,faxenumjobs,faxenumjobsa,'+
    'faxenumjobsw,faxenumports,faxenumportsa,faxenumportsw,faxenumroutingmethods,'+
    'faxenumroutingmethodsa,faxenumroutingmethodsw,faxfreebuffer,faxgetconfiguration,'+
    'faxgetconfigurationa,faxgetconfigurationw,faxgetdevicestatus,'+
    'faxgetdevicestatusa,faxgetdevicestatusw,faxgetjob,faxgetjoba,faxgetjobw,'+
    'faxgetloggingcategories,faxgetloggingcategoriesa,faxgetloggingcategoriesw,'+
    'faxgetpagedata,faxgetport,faxgetporta,faxgetportw,faxgetroutinginfo,'+
    'faxgetroutinginfoa,faxgetroutinginfow,faxinitializeeventqueue,faxopenport,'+
    'faxprintcoverpage,faxprintcoverpagea,faxprintcoverpagew,'+
    'faxregisterroutingextension,faxregisterroutingextensionw,'+
    'faxregisterserviceprovider,faxregisterserviceproviderw,faxsenddocument,'+
    'faxsenddocumenta,faxsenddocumentforbroadcast,faxsenddocumentforbroadcasta,'+
    'faxsenddocumentforbroadcastw,faxsenddocumentw,faxsetconfiguration,'+
    'faxsetconfigurationa,faxsetconfigurationw,faxsetglobalroutinginfo,'+
    'faxsetglobalroutinginfoa,faxsetglobalroutinginfow,faxsetjob,faxsetjoba,'+
    'faxsetjobw,faxsetloggingcategories,faxsetloggingcategoriesa,'+
    'faxsetloggingcategoriesw,faxsetport,faxsetporta,faxsetportw,faxsetroutinginfo,'+
    'faxsetroutinginfoa,faxsetroutinginfow,faxstartprintjob,faxstartprintjoba,'+
    'faxstartprintjobw,fbadcolumnset,fbadentrylist,fbadprop,fbadproptag,'+
    'fbadrestriction,fbadrglpnameid,fbadrglpsz,fbadrglpsza,fbadrglpszw,fbadrow,'+
    'fbadrowset,fbadsortorderset,fbinfromhex,fciaddfile,fcicreate,fcidestroy,'+
    'fciflushcabinet,fciflushfolder,fcntl,fddifilterdprindicatereceive,'+
    'fddifilterdprindicatereceivecomplete,fdecodeid,fdeinitime,fdicallenumerate,'+
    'fdicopy,fdicreate,fdidestroy,fdigetdatablock,fdigetfile,fdiiscabinet,'+
    'fdireadcfdataentry,fdireadcffileentry,fdireadpsz,fditruncatecabinet,'+
    'feclientinitialize,fequalnames,feuccodee,feuccodes,fflushimecomposition,'+
    'fgaddpunct,fgalign,fgchecklang,fgetactiveimestatus,fgetcomponentpath,'+
    'fgetconversionstatus,fgetopenimestatus,fgetopenimestatuswindow,fggetdeffont,'+
    'fggetlanginfo,fggetlanginfos,fginitpunct,fgleadbyte,fgleadbytep,fgpunct,'+
    'fgremovepunct,fgsetlanginfo,fgsetwordbreakproc,fgsyncsys,fgvalidstring,filecopy,'+
    'filedescriptor,fileencryptionstatus,fileencryptionstatusa,fileencryptionstatusw,'+
    'filegroupdescriptor,fileno,filesavemarknotexist,filesaverestore,'+
    'filesaverestoreoninf,filesize,filesizew,filetimetodosdatetime,'+
    'filetimetolocalfiletime,filetimetosystemtime,fillbuf,fillconsoleoutputattribute,'+
    'fillconsoleoutputcharacter,fillconsoleoutputcharactera,'+
    'fillconsoleoutputcharacterw,fillpath,fillrect,fillrgn,filteraddobject,'+
    'filterattachesproperties,filtercreateinstance,filterduplicate,filterfindframe,'+
    'filterfindpropertyinstance,filterflushbits,filterframe,filternppblob,'+
    'fimemessage,fimewordregister,findactctxsectionguid,findactctxsectionstring,'+
    'findactctxsectionstringa,findactctxsectionstringw,findadapterhandler,'+
    'findaddressinfobyaddress,findaddressinfobyname,findatom,findatoma,findatomw,'+
    'findcertsbyissuer,findclose,findclosechangenotification,'+
    'findcloseprinterchangenotification,findcloseurlcache,finddebuginfofile,'+
    'finddebuginfofileex,findexecutable,findexecutablea,findexecutableimage,'+
    'findexecutableimageex,findexecutablew,findexedlgproc,findfileinsearchpath,'+
    'findfirstchangenotification,findfirstchangenotificationa,'+
    'findfirstchangenotificationw,findfirstfile,findfirstfilea,findfirstfileex,'+
    'findfirstfileexa,findfirstfileexw,findfirstfilew,findfirstfreeace,'+
    'findfirstprinterchangenotification,findfirsturlcachecontainer,'+
    'findfirsturlcachecontainera,findfirsturlcachecontainerw,findfirsturlcacheentry,'+
    'findfirsturlcacheentrya,findfirsturlcacheentryex,findfirsturlcacheentryexa,'+
    'findfirsturlcacheentryexw,findfirsturlcacheentryw,findfirsturlcachegroup,'+
    'findfirstvolume,findfirstvolumea,findfirstvolumemountpoint,'+
    'findfirstvolumemountpointa,findfirstvolumemountpointw,findfirstvolumew,'+
    'finditemwnd,findmediatype,findmediatypeclass,findmimefromdata,'+
    'findnetbiosdomainname,findnextchangenotification,findnextfile,findnextfilea,'+
    'findnextfilew,findnextframe,findnextprinterchangenotification,'+
    'findnexturlcachecontainer,findnexturlcachecontainera,findnexturlcachecontainerw,'+
    'findnexturlcacheentry,findnexturlcacheentrya,findnexturlcacheentryex,'+
    'findnexturlcacheentryexa,findnexturlcacheentryexw,findnexturlcacheentryw,'+
    'findnexturlcachegroup,findnextvolume,findnextvolumea,findnextvolumemountpoint,'+
    'findnextvolumemountpointa,findnextvolumemountpointw,findnextvolumew,findoneof,'+
    'findp3ppolicysymbol,findpreviousframe,findpropertyinstance,'+
    'findpropertyinstancerestart,findreplace,findresource,findresourcea,'+
    'findresourceex,findresourceexa,findresourceexw,findresourcew,findservices,'+
    'findservicescallback,findservicescancel,findservicesclose,findtext,findtexta,'+
    'findtextex,findtextw,findunknownblobcategories,findunknownblobtags,'+
    'findvolumeclose,findvolumemountpointclose,findwindow,findwindowa,findwindowex,'+
    'findwindowexa,findwindowexw,findwindoww,finitime,fix_tree_cost_estimates,'+
    'fixbrushorgex,fixie,fixmapi,flashwindow,flashwindowex,flataddress,'+
    'flatsb_enablescrollbar,flatsb_getscrollinfo,flatsb_getscrollpos,'+
    'flatsb_getscrollprop,flatsb_getscrollrange,flatsb_setscrollinfo,'+
    'flatsb_setscrollpos,flatsb_setscrollprop,flatsb_setscrollrange,'+
    'flatsb_showscrollbar,flattenpath,floatobj_add,floatobj_addfloat,'+
    'floatobj_addlong,floatobj_div,floatobj_divfloat,floatobj_divlong,floatobj_equal,'+
    'floatobj_equallong,floatobj_getfloat,floatobj_getlong,floatobj_greaterthan,'+
    'floatobj_greaterthanlong,floatobj_lessthan,floatobj_lessthanlong,floatobj_mul,'+
    'floatobj_mulfloat,floatobj_mullong,floatobj_neg,floatobj_setfloat,'+
    'floatobj_setlong,floatobj_sub,floatobj_subfloat,floatobj_sublong,floodfill,'+
    'flush_all_pending_blocks,flush_block,flush_output_bit_buffer,flushcab,'+
    'flushconsoleinputbuffer,flushfilebuffers,flushinstructioncache,flushipnettable,'+
    'flushipnettablefromstack,flushprinter,flushq,flushtrace,flushtracea,flushtracew,'+
    'flushviewoffile,fm_byte_flags,fm_byte_set,fm_byte10,fm_byte16,fm_dword_flags,'+
    'fm_dword_set,fm_dword10,fm_dword16,fm_hex_string,fm_largeint16,fm_property_name,'+
    'fm_string,fm_swap_dword10,fm_swap_dword16,fm_swap_word10,fm_swap_word16,fm_time,'+
    'fm_time_ex,fm_word_flags,fm_word_set,fm_word10,fm_word16,fmextensionproc,'+
    'fmextensionprocw,fmtidtopropstgname,fnulluuid,folderdestroy,folderflush,'+
    'folderinit,foldstring,foldstringa,foldstringw,fontdialog,'+
    'fontobj_cgetallglyphhandles,fontobj_cgetglyphs,fontobj_pfdg,fontobj_pifi,'+
    'fontobj_pjopentypetablepointer,fontobj_pqueryglyphattrs,'+
    'fontobj_pvtruetypefontfile,fontobj_pwszfontfilepaths,fontobj_pxogetxform,'+
    'fontobj_vgetinfo,forcemastermerge,forcenexuslookup,forcenexuslookupex,'+
    'forcenexuslookupexw,forcesyncfgpolicy,forceunloaddriver,fork,formatbyteflags,'+
    'formatchardlgproc,formatdirectoryname,formatdwordflags,formatlabeledbyteset,'+
    'formatlabeledbytesetasflags,formatlabeleddwordset,formatlabeleddwordsetasflags,'+
    'formatlabeledwordset,formatlabeledwordsetasflags,formatmessage,formatmessagea,'+
    'formatmessagew,formatmsgbox,formatmsgresource,formatprinterforregistrykey,'+
    'formatpropertydataashexstring,formatpropertydataasint64,'+
    'formatpropertydataasstring,formatpropertydataastime,formatpropertydataasword,'+
    'formatpropertyinstance,formatregistrykeyforprinter,formattimeasstring,'+
    'formatwordflags,fpathconf,fprintf,fpropcompareprop,fpropcontainsprop,'+
    'fpropexists,fpuabs,fpuadd,fpuarccos,fpuarccosh,fpuarcsin,fpuarcsinh,fpuarctan,'+
    'fpuarctanh,fpuatofl,fpuchs,fpucomp,fpucos,fpucosh,fpudiv,fpueexpx,fpuexam,'+
    'fpufltoa,fpulnx,fpulogx,fpumul,fpuround,fpusin,fpusinh,fpusize,fpusqrt,fpustate,'+
    'fpusub,fputan,fputanh,fputexpx,fputrunc,fpuxexpy,frame3d,framectrl,framegrp,'+
    'framerecognize,framerect,framergn,framewindow,fredefcommand,free,'+
    'free_compressed_output_buffer,free_decompression_memory,freeaddrinfo,'+
    'freeaddrinfow,freeadsmem,freeadsstr,freeallimeobject,freeattributes,freeb,'+
    'freeconsole,freecontextbuffer,freecredentialshandle,freeddelparam,'+
    'freeencryptedfilekeyinfo,freeencryptioncertificatehashlist,'+
    'freeenvironmentstrings,freeenvironmentstringsa,freeenvironmentstringsw,'+
    'freegpolist,freegpolista,freegpolistw,freeiconlist,freeinheritedfromarray,'+
    'freeiprbuff,freelibrary,freelibraryandexitthread,freememory,freemrulist,freemsg,'+
    'freenetworkbuffer,freeobject,freeothernames,freep3pobject,freepadrlist,'+
    'freeprinternotifyinfo,freepropvariantarray,freeprows,freeresource,freersopquery,'+
    'freersopqueryresults,freesid,freessdpmessage,freeurlcachespace,'+
    'freeurlcachespacea,freeurlcachespacew,freeuserphysicalpages,freevirtualbuffer,'+
    'fregisterhelpid,fseparatewow,fsetactiveimestatus,fsetconversionstatus,'+
    'fsetimefont,fsetimefonth,fsetimewndproc,fsetopenimestatus,'+
    'fsetopenimestatuswindow,fsjiscode,fsrtlacquirefileexclusive,'+
    'fsrtladdbasemcbentry,fsrtladdlargemcbentry,fsrtladdmcbentry,'+
    'fsrtladdtotunnelcache,fsrtlallocatefilelock,fsrtlallocatepool,'+
    'fsrtlallocatepoolwithquota,fsrtlallocatepoolwithquotatag,'+
    'fsrtlallocatepoolwithtag,fsrtlallocateresource,fsrtlarenamesequal,'+
    'fsrtlbalancereads,fsrtlchecklockforreadaccess,fsrtlchecklockforwriteaccess,'+
    'fsrtlcheckoplock,fsrtlcopyread,fsrtlcopywrite,fsrtlcreatesectionfordatascan,'+
    'fsrtlcurrentbatchoplock,fsrtldeletekeyfromtunnelcache,fsrtldeletetunnelcache,'+
    'fsrtlderegisteruncprovider,fsrtldissectdbcs,fsrtldissectname,'+
    'fsrtldoesdbcscontainwildcards,fsrtldoesnamecontainwildcards,'+
    'fsrtlfastchecklockforread,fsrtlfastchecklockforwrite,fsrtlfastunlockall,'+
    'fsrtlfastunlockallbykey,fsrtlfastunlocksingle,fsrtlfindintunnelcache,'+
    'fsrtlfreefilelock,fsrtlgetfilesize,fsrtlgetnextbasemcbentry,'+
    'fsrtlgetnextfilelock,fsrtlgetnextlargemcbentry,fsrtlgetnextmcbentry,'+
    'fsrtlincrementccfastreadnotpossible,fsrtlincrementccfastreadnowait,'+
    'fsrtlincrementccfastreadresourcemiss,fsrtlincrementccfastreadwait,'+
    'fsrtlinitializebasemcb,fsrtlinitializefilelock,fsrtlinitializelargemcb,'+
    'fsrtlinitializemcb,fsrtlinitializeoplock,fsrtlinitializetunnelcache,'+
    'fsrtlinsertperfileobjectcontext,fsrtlinsertperstreamcontext,'+
    'fsrtlisdbcsinexpression,fsrtlisfatdbcslegal,fsrtlishpfsdbcslegal,'+
    'fsrtlisnameinexpression,fsrtlisntstatusexpected,fsrtlispagingfile,'+
    'fsrtlistotaldevicefailure,fsrtllegalansicharacterarray,fsrtllookupbasemcbentry,'+
    'fsrtllookuplargemcbentry,fsrtllookuplastbasemcbentry,'+
    'fsrtllookuplastbasemcbentryandindex,fsrtllookuplastlargemcbentry,'+
    'fsrtllookuplastlargemcbentryandindex,fsrtllookuplastmcbentry,'+
    'fsrtllookupmcbentry,fsrtllookupperfileobjectcontext,'+
    'fsrtllookupperstreamcontextinternal,fsrtlmdlread,fsrtlmdlreadcomplete,'+
    'fsrtlmdlreadcompletedev,fsrtlmdlreaddev,fsrtlmdlwritecomplete,'+
    'fsrtlmdlwritecompletedev,fsrtlnormalizentstatus,fsrtlnotifychangedirectory,'+
    'fsrtlnotifycleanup,fsrtlnotifyfilterchangedirectory,'+
    'fsrtlnotifyfilterreportchange,fsrtlnotifyfullchangedirectory,'+
    'fsrtlnotifyfullreportchange,fsrtlnotifyinitializesync,fsrtlnotifyreportchange,'+
    'fsrtlnotifyuninitializesync,fsrtlnotifyvolumeevent,fsrtlnumberofrunsinbasemcb,'+
    'fsrtlnumberofrunsinlargemcb,fsrtlnumberofrunsinmcb,fsrtloplockfsctrl,'+
    'fsrtloplockisfastiopossible,fsrtlpostpagingfilestackoverflow,'+
    'fsrtlpoststackoverflow,fsrtlpreparemdlwrite,fsrtlpreparemdlwritedev,'+
    'fsrtlprivatelock,fsrtlprocessfilelock,fsrtlregisterfilesystemfiltercallbacks,'+
    'fsrtlregisteruncprovider,fsrtlreleasefile,fsrtlremovebasemcbentry,'+
    'fsrtlremovelargemcbentry,fsrtlremovemcbentry,fsrtlremoveperfileobjectcontext,'+
    'fsrtlremoveperstreamcontext,fsrtlresetbasemcb,fsrtlresetlargemcb,'+
    'fsrtlsplitbasemcb,fsrtlsplitlargemcb,fsrtlsyncvolumes,'+
    'fsrtlteardownperstreamcontexts,fsrtltruncatebasemcb,fsrtltruncatelargemcb,'+
    'fsrtltruncatemcb,fsrtluninitializebasemcb,fsrtluninitializefilelock,'+
    'fsrtluninitializelargemcb,fsrtluninitializemcb,fsrtluninitializeoplock,fstat,'+
    'ft_exit0,ft_exit12,ft_exit16,ft_exit20,ft_exit24,ft_exit28,ft_exit32,ft_exit36,'+
    'ft_exit4,ft_exit40,ft_exit44,ft_exit48,ft_exit52,ft_exit56,ft_exit8,ft_prolog,'+
    'ft_thunk,ftadcft,ftaddft,ftdivftbogus,fterminatorcode,ftgregisteridleroutine,'+
    'ftmuldw,ftmuldwdw,ftnegft,ftpcommand,ftpcommanda,ftpcommandw,ftpcreatedirectory,'+
    'ftpcreatedirectorya,ftpcreatedirectoryw,ftpdeletefile,ftpdeletefilea,'+
    'ftpdeletefilew,ftpfindfirstfile,ftpfindfirstfilea,ftpfindfirstfilew,'+
    'ftpgetcurrentdirectory,ftpgetcurrentdirectorya,ftpgetcurrentdirectoryw,'+
    'ftpgetfile,ftpgetfilea,ftpgetfileex,ftpgetfilesize,ftpgetfilew,ftpopenfile,'+
    'ftpopenfilea,ftpopenfilew,ftpputfile,ftpputfilea,ftpputfileex,ftpputfilew,'+
    'ftpremovedirectory,ftpremovedirectorya,ftpremovedirectoryw,ftprenamefile,'+
    'ftprenamefilea,ftprenamefilew,ftpsetcurrentdirectory,ftpsetcurrentdirectorya,'+
    'ftpsetcurrentdirectoryw,ftruncate,ftsubft,fvaddpunct,fvalidatelogfont,fvalign,'+
    'fvchecklang,fvfreecharobject,fvfreeconvobject,fvfreelangobject,'+
    'fvfreepunctobject,fvgetlanginfo,fvgetlanginfos,fvinitpunct,fvleadbyte,'+
    'fvleadbytep,fvpunct,fvregdecodeproc,fvregdecodeprocex,fvregencodeproc,'+
    'fvremovedecodeproc,fvremoveencodeproc,fvremovepunct,fvsetlanginfo,'+
    'fvsetwordbreakproc,fvvalidstring,fwbindfwinterfacetoadapter,'+
    'fwconnectionrequestfailed,fwcreateinterface,fwdeleteinterface,'+
    'fwdisablefwinterface,fwenablefwinterface,fwgetinterface,fwgetnotificationresult,'+
    'fwgetstaticnetbiosnames,fwisstarted,fwnotifyconnectionrequest,fwprintf,'+
    'fwsetinterface,fwsetstaticnetbiosnames,fwstart,fwstop,'+
    'fwunbindfwinterfacefromadapter,fwupdateconfig,fwupdateroutetable,'+
    'g_rgscardrawpci,g_rgscardt0pci,gcverifycachelookup,gdiartificialdecrementdriver,'+
    'gdicomment,gdideletespoolfilehandle,gdienddocemf,gdiendpageemf,gdiflush,'+
    'gdigetbatchlimit,gdigetdc,gdigetdevmodeforpage,gdigetpagecount,gdigetpagehandle,'+
    'gdigetspoolfilehandle,gdigetspoolmessage,gdiinitspool,gdipaddpatharc,'+
    'gdipaddpatharci,gdipaddpathbezier,gdipaddpathbezieri,gdipaddpathbeziers,'+
    'gdipaddpathbeziersi,gdipaddpathclosedcurve,gdipaddpathclosedcurve2,'+
    'gdipaddpathclosedcurve2i,gdipaddpathclosedcurvei,gdipaddpathcurve,'+
    'gdipaddpathcurve2,gdipaddpathcurve2i,gdipaddpathcurve3,gdipaddpathcurve3i,'+
    'gdipaddpathcurvei,gdipaddpathellipse,gdipaddpathellipsei,gdipaddpathline,'+
    'gdipaddpathline2,gdipaddpathline2i,gdipaddpathlinei,gdipaddpathpath,'+
    'gdipaddpathpie,gdipaddpathpiei,gdipaddpathpolygon,gdipaddpathpolygoni,'+
    'gdipaddpathrectangle,gdipaddpathrectanglei,gdipaddpathrectangles,'+
    'gdipaddpathrectanglesi,gdipaddpathstring,gdipaddpathstringi,gdipalloc,'+
    'gdipbegincontainer,gdipbegincontainer2,gdipbegincontaineri,gdipbitmapgetpixel,'+
    'gdipbitmaplockbits,gdipbitmapsetpixel,gdipbitmapsetresolution,'+
    'gdipbitmapunlockbits,gdipclearpathmarkers,gdipclonebitmaparea,'+
    'gdipclonebitmapareai,gdipclonebrush,gdipclonecustomlinecap,gdipclonefont,'+
    'gdipclonefontfamily,gdipcloneimage,gdipcloneimageattributes,gdipclonematrix,'+
    'gdipclonepath,gdipclonepen,gdipcloneregion,gdipclonestringformat,'+
    'gdipclosepathfigure,gdipclosepathfigures,gdipcombineregionpath,'+
    'gdipcombineregionrect,gdipcombineregionrecti,gdipcombineregionregion,'+
    'gdipcomment,gdipcreateadjustablearrowcap,gdipcreatebitmapfromdirectdrawsurface,'+
    'gdipcreatebitmapfromfile,gdipcreatebitmapfromfileicm,gdipcreatebitmapfromgdidib,'+
    'gdipcreatebitmapfromgraphics,gdipcreatebitmapfromhbitmap,'+
    'gdipcreatebitmapfromhicon,gdipcreatebitmapfromresource,'+
    'gdipcreatebitmapfromscan0,gdipcreatebitmapfromstream,'+
    'gdipcreatebitmapfromstreamicm,gdipcreatecachedbitmap,gdipcreatecustomlinecap,'+
    'gdipcreatefont,gdipcreatefontfamilyfromname,gdipcreatefontfromdc,'+
    'gdipcreatefontfromlogfont,gdipcreatefontfromlogfonta,gdipcreatefontfromlogfontw,'+
    'gdipcreatefromhdc,gdipcreatefromhdc2,gdipcreatefromhwnd,gdipcreatefromhwndicm,'+
    'gdipcreatehalftonepalette,gdipcreatehatchbrush,gdipcreatehbitmapfrombitmap,'+
    'gdipcreatehiconfrombitmap,gdipcreateimageattributes,gdipcreatelinebrush,'+
    'gdipcreatelinebrushfromrect,gdipcreatelinebrushfromrecti,'+
    'gdipcreatelinebrushfromrectwithangle,gdipcreatelinebrushfromrectwithanglei,'+
    'gdipcreatelinebrushi,gdipcreatematrix,gdipcreatematrix2,gdipcreatematrix3,'+
    'gdipcreatematrix3i,gdipcreatemetafilefromemf,gdipcreatemetafilefromfile,'+
    'gdipcreatemetafilefromstream,gdipcreatemetafilefromwmf,'+
    'gdipcreatemetafilefromwmffile,gdipcreatepath,gdipcreatepath2,gdipcreatepath2i,'+
    'gdipcreatepathgradient,gdipcreatepathgradientfrompath,gdipcreatepathgradienti,'+
    'gdipcreatepathiter,gdipcreatepen1,gdipcreatepen2,gdipcreateregion,'+
    'gdipcreateregionhrgn,gdipcreateregionpath,gdipcreateregionrect,'+
    'gdipcreateregionrecti,gdipcreateregionrgndata,gdipcreatesolidfill,'+
    'gdipcreatestreamonfile,gdipcreatestringformat,gdipcreatetexture,'+
    'gdipcreatetexture2,gdipcreatetexture2i,gdipcreatetextureia,gdipcreatetextureiai,'+
    'gdipdeletebrush,gdipdeletecachedbitmap,gdipdeletecustomlinecap,gdipdeletefont,'+
    'gdipdeletefontfamily,gdipdeletegraphics,gdipdeletematrix,gdipdeletepath,'+
    'gdipdeletepathiter,gdipdeletepen,gdipdeleteprivatefontcollection,'+
    'gdipdeleteregion,gdipdeletestringformat,gdipdisposeimage,'+
    'gdipdisposeimageattributes,gdipdrawarc,gdipdrawarci,gdipdrawbezier,'+
    'gdipdrawbezieri,gdipdrawbeziers,gdipdrawbeziersi,gdipdrawcachedbitmap,'+
    'gdipdrawclosedcurve,gdipdrawclosedcurve2,gdipdrawclosedcurve2i,'+
    'gdipdrawclosedcurvei,gdipdrawcurve,gdipdrawcurve2,gdipdrawcurve2i,'+
    'gdipdrawcurve3,gdipdrawcurve3i,gdipdrawcurvei,gdipdrawdriverstring,'+
    'gdipdrawellipse,gdipdrawellipsei,gdipdrawimage,gdipdrawimagei,'+
    'gdipdrawimagepointrect,gdipdrawimagepointrecti,gdipdrawimagepoints,'+
    'gdipdrawimagepointsi,gdipdrawimagepointsrect,gdipdrawimagepointsrecti,'+
    'gdipdrawimagerect,gdipdrawimagerecti,gdipdrawimagerectrect,'+
    'gdipdrawimagerectrecti,gdipdrawline,gdipdrawlinei,gdipdrawlines,gdipdrawlinesi,'+
    'gdipdrawpath,gdipdrawpie,gdipdrawpiei,gdipdrawpolygon,gdipdrawpolygoni,'+
    'gdipdrawrectangle,gdipdrawrectanglei,gdipdrawrectangles,gdipdrawrectanglesi,'+
    'gdipdrawstring,gdipemftowmfbits,gdipendcontainer,gdipenumeratemetafiledestpoint,'+
    'gdipenumeratemetafiledestpointi,gdipenumeratemetafiledestpoints,'+
    'gdipenumeratemetafiledestpointsi,gdipenumeratemetafiledestrect,'+
    'gdipenumeratemetafiledestrecti,gdipenumeratemetafilesrcrectdestpoint,'+
    'gdipenumeratemetafilesrcrectdestpointi,gdipenumeratemetafilesrcrectdestpoints,'+
    'gdipenumeratemetafilesrcrectdestpointsi,gdipenumeratemetafilesrcrectdestrect,'+
    'gdipenumeratemetafilesrcrectdestrecti,gdipfillclosedcurve,gdipfillclosedcurve2,'+
    'gdipfillclosedcurve2i,gdipfillclosedcurvei,gdipfillellipse,gdipfillellipsei,'+
    'gdipfillpath,gdipfillpie,gdipfillpiei,gdipfillpolygon,gdipfillpolygon2,'+
    'gdipfillpolygon2i,gdipfillpolygoni,gdipfillrectangle,gdipfillrectanglei,'+
    'gdipfillrectangles,gdipfillrectanglesi,gdipfillregion,gdipflattenpath,gdipflush,'+
    'gdipfree,gdipgetadjustablearrowcapfillstate,gdipgetadjustablearrowcapheight,'+
    'gdipgetadjustablearrowcapmiddleinset,gdipgetadjustablearrowcapwidth,'+
    'gdipgetallpropertyitems,gdipgetbrushtype,gdipgetcellascent,gdipgetcelldescent,'+
    'gdipgetclip,gdipgetclipbounds,gdipgetclipboundsi,gdipgetcompositingmode,'+
    'gdipgetcompositingquality,gdipgetcustomlinecapbasecap,'+
    'gdipgetcustomlinecapbaseinset,gdipgetcustomlinecapstrokecaps,'+
    'gdipgetcustomlinecapstrokejoin,gdipgetcustomlinecaptype,'+
    'gdipgetcustomlinecapwidthscale,gdipgetdc,gdipgetdpix,gdipgetdpiy,'+
    'gdipgetemheight,gdipgetencoderparameterlist,gdipgetencoderparameterlistsize,'+
    'gdipgetfamily,gdipgetfamilyname,gdipgetfontcollectionfamilycount,'+
    'gdipgetfontcollectionfamilylist,gdipgetfontheight,gdipgetfontheightgivendpi,'+
    'gdipgetfontsize,gdipgetfontstyle,gdipgetfontunit,'+
    'gdipgetgenericfontfamilymonospace,gdipgetgenericfontfamilysansserif,'+
    'gdipgetgenericfontfamilyserif,gdipgethatchbackgroundcolor,'+
    'gdipgethatchforegroundcolor,gdipgethatchstyle,gdipgethemffrommetafile,'+
    'gdipgetimageattributesadjustedpalette,gdipgetimagebounds,gdipgetimagedecoders,'+
    'gdipgetimagedecoderssize,gdipgetimagedimension,gdipgetimageencoders,'+
    'gdipgetimageencoderssize,gdipgetimageflags,gdipgetimagegraphicscontext,'+
    'gdipgetimageheight,gdipgetimagehorizontalresolution,gdipgetimagepalette,'+
    'gdipgetimagepalettesize,gdipgetimagepixelformat,gdipgetimagerawformat,'+
    'gdipgetimagethumbnail,gdipgetimagetype,gdipgetimageverticalresolution,'+
    'gdipgetimagewidth,gdipgetinterpolationmode,gdipgetlineblend,'+
    'gdipgetlineblendcount,gdipgetlinecolors,gdipgetlinegammacorrection,'+
    'gdipgetlinepresetblend,gdipgetlinepresetblendcount,gdipgetlinerect,'+
    'gdipgetlinerecti,gdipgetlinespacing,gdipgetlinetransform,gdipgetlinewrapmode,'+
    'gdipgetlogfont,gdipgetlogfonta,gdipgetlogfontw,gdipgetmatrixelements,'+
    'gdipgetmetafiledownlevelrasterizationlimit,gdipgetmetafileheaderfromemf,'+
    'gdipgetmetafileheaderfromfile,gdipgetmetafileheaderfrommetafile,'+
    'gdipgetmetafileheaderfromstream,gdipgetmetafileheaderfromwmf,'+
    'gdipgetnearestcolor,gdipgetpagescale,gdipgetpageunit,gdipgetpathdata,'+
    'gdipgetpathfillmode,gdipgetpathgradientblend,gdipgetpathgradientblendcount,'+
    'gdipgetpathgradientcentercolor,gdipgetpathgradientcenterpoint,'+
    'gdipgetpathgradientcenterpointi,gdipgetpathgradientfocusscales,'+
    'gdipgetpathgradientgammacorrection,gdipgetpathgradientpath,'+
    'gdipgetpathgradientpointcount,gdipgetpathgradientpresetblend,'+
    'gdipgetpathgradientpresetblendcount,gdipgetpathgradientrect,'+
    'gdipgetpathgradientrecti,gdipgetpathgradientsurroundcolorcount,'+
    'gdipgetpathgradientsurroundcolorswithcount,gdipgetpathgradienttransform,'+
    'gdipgetpathgradientwrapmode,gdipgetpathlastpoint,gdipgetpathpoints,'+
    'gdipgetpathpointsi,gdipgetpathtypes,gdipgetpathworldbounds,'+
    'gdipgetpathworldboundsi,gdipgetpenbrushfill,gdipgetpencolor,'+
    'gdipgetpencompoundarray,gdipgetpencompoundcount,gdipgetpencustomendcap,'+
    'gdipgetpencustomstartcap,gdipgetpendasharray,gdipgetpendashcap197819,'+
    'gdipgetpendashcount,gdipgetpendashoffset,gdipgetpendashstyle,gdipgetpenendcap,'+
    'gdipgetpenfilltype,gdipgetpenlinejoin,gdipgetpenmiterlimit,gdipgetpenmode,'+
    'gdipgetpenstartcap,gdipgetpentransform,gdipgetpenunit,gdipgetpenwidth,'+
    'gdipgetpixeloffsetmode,gdipgetpointcount,gdipgetpropertycount,'+
    'gdipgetpropertyidlist,gdipgetpropertyitem,gdipgetpropertyitemsize,'+
    'gdipgetpropertysize,gdipgetregionbounds,gdipgetregionboundsi,gdipgetregiondata,'+
    'gdipgetregiondatasize,gdipgetregionhrgn,gdipgetregionscans,'+
    'gdipgetregionscanscount,gdipgetregionscansi,gdipgetrenderingorigin,'+
    'gdipgetsmoothingmode,gdipgetsolidfillcolor,gdipgetstringformatalign,'+
    'gdipgetstringformatdigitsubstitution,gdipgetstringformatflags,'+
    'gdipgetstringformathotkeyprefix,gdipgetstringformatlinealign,'+
    'gdipgetstringformatmeasurablecharacterrangecount,gdipgetstringformattabstopcount,'+
    'gdipgetstringformattabstops,gdipgetstringformattrimming,gdipgettextcontrast,'+
    'gdipgettextrenderinghint,gdipgettextureimage,gdipgettexturetransform,'+
    'gdipgettexturewrapmode,gdipgetvisibleclipbounds,gdipgetvisibleclipboundsi,'+
    'gdipgetworldtransform,gdipgraphicsclear,gdipimageforcevalidation,'+
    'gdipimagegetframecount,gdipimagegetframedimensionscount,'+
    'gdipimagegetframedimensionslist,gdipimagerotateflip,gdipimageselectactiveframe,'+
    'gdipinvertmatrix,gdipisclipempty,gdipisemptyregion,gdipisequalregion,'+
    'gdipisinfiniteregion,gdipismatrixequal,gdipismatrixidentity,'+
    'gdipismatrixinvertible,gdipisoutlinevisiblepathpoint,'+
    'gdipisoutlinevisiblepathpointi,gdipisstyleavailable,gdipisvisibleclipempty,'+
    'gdipisvisiblepathpoint,gdipisvisiblepathpointi,gdipisvisiblepoint,'+
    'gdipisvisiblepointi,gdipisvisiblerect,gdipisvisiblerecti,'+
    'gdipisvisibleregionpoint,gdipisvisibleregionpointi,gdipisvisibleregionrect,'+
    'gdipisvisibleregionrecti,gdiplaydcscript,gdiplayemf,gdiplayjournal,'+
    'gdiplaypageemf,gdiplayprivatepageemf,gdiplayscript,gdiplayspoolstream,'+
    'gdiploadimagefromfile,gdiploadimagefromfileicm,gdiploadimagefromstream,'+
    'gdiploadimagefromstreamicm,gdiplusnotificationhook,gdiplusnotificationunhook,'+
    'gdiplusshutdown,gdiplusstartup,gdipmeasurecharacterranges,'+
    'gdipmeasuredriverstring,gdipmeasurestring,gdipmultiplylinetransform,'+
    'gdipmultiplymatrix,gdipmultiplypathgradienttransform,gdipmultiplypentransform,'+
    'gdipmultiplytexturetransform,gdipmultiplyworldtransform,'+
    'gdipnewinstalledfontcollection,gdipnewprivatefontcollection,'+
    'gdippathitercopydata,gdippathiterenumerate,gdippathitergetcount,'+
    'gdippathitergetsubpathcount,gdippathiterhascurve,gdippathiterisvalid,'+
    'gdippathiternextmarker,gdippathiternextmarkerpath,gdippathiternextpathtype,'+
    'gdippathiternextsubpath,gdippathiternextsubpathpath,gdippathiterrewind,'+
    'gdipplaymetafilerecord,gdipprivateaddfontfile,gdipprivateaddmemoryfont,'+
    'gdiprecordmetafile,gdiprecordmetafilefilename,gdiprecordmetafilefilenamei,'+
    'gdiprecordmetafilei,gdiprecordmetafilestream,gdiprecordmetafilestreami,'+
    'gdipreleasedc,gdipremovepropertyitem,gdipresetclip,gdipresetimageattributes,'+
    'gdipresetlinetransform,gdipresetpagetransform,gdipresetpath,'+
    'gdipresetpathgradienttransform,gdipresetpentransform,gdipresettexturetransform,'+
    'gdipresetworldtransform,gdiprestoregraphics,gdipreversepath,'+
    'gdiprotatelinetransform,gdiprotatematrix,gdiprotatepathgradienttransform,'+
    'gdiprotatepentransform,gdiprotatetexturetransform,gdiprotateworldtransform,'+
    'gdipsaveadd,gdipsaveaddimage,gdipsavegraphics,gdipsaveimagetofile,'+
    'gdipsaveimagetostream,gdipscalelinetransform,gdipscalematrix,'+
    'gdipscalepathgradienttransform,gdipscalepentransform,gdipscaletexturetransform,'+
    'gdipscaleworldtransform,gdipsetadjustablearrowcapfillstate,'+
    'gdipsetadjustablearrowcapheight,gdipsetadjustablearrowcapmiddleinset,'+
    'gdipsetadjustablearrowcapwidth,gdipsetclipgraphics,gdipsetcliphrgn,'+
    'gdipsetclippath,gdipsetcliprect,gdipsetcliprecti,gdipsetclipregion,'+
    'gdipsetcompositingmode,gdipsetcompositingquality,gdipsetcustomlinecapbasecap,'+
    'gdipsetcustomlinecapbaseinset,gdipsetcustomlinecapstrokecaps,'+
    'gdipsetcustomlinecapstrokejoin,gdipsetcustomlinecapwidthscale,gdipsetempty,'+
    'gdipsetimageattributescachedbackground,gdipsetimageattributescolorkeys,'+
    'gdipsetimageattributescolormatrix,gdipsetimageattributesgamma,'+
    'gdipsetimageattributesnoop,gdipsetimageattributesoutputchannel,'+
    'gdipsetimageattributesoutputchannelcolorprofile,gdipsetimageattributesremaptable,'+
    'gdipsetimageattributesthreshold,gdipsetimageattributestoidentity,'+
    'gdipsetimageattributeswrapmode,gdipsetimagepalette,gdipsetinfinite,'+
    'gdipsetinterpolationmode,gdipsetlineblend,gdipsetlinecolors,'+
    'gdipsetlinegammacorrection,gdipsetlinelinearblend,gdipsetlinepresetblend,'+
    'gdipsetlinesigmablend,gdipsetlinetransform,gdipsetlinewrapmode,'+
    'gdipsetmatrixelements,gdipsetmetafiledownlevelrasterizationlimit,'+
    'gdipsetpagescale,gdipsetpageunit,gdipsetpathfillmode,gdipsetpathgradientblend,'+
    'gdipsetpathgradientcentercolor,gdipsetpathgradientcenterpoint,'+
    'gdipsetpathgradientcenterpointi,gdipsetpathgradientfocusscales,'+
    'gdipsetpathgradientgammacorrection,gdipsetpathgradientlinearblend,'+
    'gdipsetpathgradientpath,gdipsetpathgradientpresetblend,'+
    'gdipsetpathgradientsigmablend,gdipsetpathgradientsurroundcolorswithcount,'+
    'gdipsetpathgradienttransform,gdipsetpathgradientwrapmode,gdipsetpathmarker,'+
    'gdipsetpenbrushfill,gdipsetpencolor,gdipsetpencompoundarray,'+
    'gdipsetpencustomendcap,gdipsetpencustomstartcap,gdipsetpendasharray,'+
    'gdipsetpendashcap197819,gdipsetpendashoffset,gdipsetpendashstyle,'+
    'gdipsetpenendcap,gdipsetpenlinecap197819,gdipsetpenlinejoin,'+
    'gdipsetpenmiterlimit,gdipsetpenmode,gdipsetpenstartcap,gdipsetpentransform,'+
    'gdipsetpenunit,gdipsetpenwidth,gdipsetpixeloffsetmode,gdipsetpropertyitem,'+
    'gdipsetrenderingorigin,gdipsetsmoothingmode,gdipsetsolidfillcolor,'+
    'gdipsetstringformatalign,gdipsetstringformatdigitsubstitution,'+
    'gdipsetstringformatflags,gdipsetstringformathotkeyprefix,'+
    'gdipsetstringformatlinealign,gdipsetstringformatmeasurablecharacterranges,'+
    'gdipsetstringformattabstops,gdipsetstringformattrimming,gdipsettextcontrast,'+
    'gdipsettextrenderinghint,gdipsettexturetransform,gdipsettexturewrapmode,'+
    'gdipsetworldtransform,gdipshearmatrix,gdipstartpathfigure,'+
    'gdipstringformatgetgenericdefault,gdipstringformatgetgenerictypographic,'+
    'gdiptestcontrol,gdiptransformmatrixpoints,gdiptransformmatrixpointsi,'+
    'gdiptransformpath,gdiptransformpoints,gdiptransformpointsi,gdiptransformregion,'+
    'gdiptranslateclip,gdiptranslateclipi,gdiptranslatelinetransform,'+
    'gdiptranslatematrix,gdiptranslatepathgradienttransform,'+
    'gdiptranslatepentransform,gdiptranslateregion,gdiptranslateregioni,'+
    'gdiptranslatetexturetransform,gdiptranslateworldtransform,'+
    'gdipvectortransformmatrixpoints,gdipvectortransformmatrixpointsi,gdipwarppath,'+
    'gdipwidenpath,gdipwindingmodeoutline,gdiqueryfonts,gdiresetdcemf,'+
    'gdisetbatchlimit,gdistartdocemf,gdistartpageemf,gen_bitlen,gen_codes,'+
    'genchangedata,genclone,gencopy,gendraw,genenumformat,genequal,'+
    'generateconsolectrlevent,generatecopyfilepaths,generatedirefs,'+
    'generategrouppolicy,generatename,generatersoppolicy,generatesessionkey,'+
    'gengetdata,genquerybounds,genrelease,gensavetostream,gensetdata,'+
    'get_aligned_stats,get_block_stats,get_distances_from_literals,'+
    'get_final_repeated_offset_states,get_ml,getacceptexsockaddrs,getacceptlanguages,'+
    'getacceptlanguagesa,getacceptlanguagesw,getaccesspermissionsforobject,'+
    'getaccesspermissionsforobjecta,getaccesspermissionsforobjectw,getace,'+
    'getaclinformation,getacp,getactiveobject,getactivepwrscheme,getactivewindow,'+
    'getadapterindex,getadaptername,getadapternamefrommacaddr,'+
    'getadapternamefrommacaddrw,getadapternamefromnumber,getadapternamew,'+
    'getadapternumberfromname,getadapterordermap,getadaptersaddresses,'+
    'getadaptersinfo,getaddressbyname,getaddressbynamea,getaddressbynamew,'+
    'getaddressdatabaseinstancedata,getaddressinfo,getaddressinfobyname,getaddrinfo,'+
    'getaddrinfow,getadmin,getaf,getah,getal,getallusersprofiledirectory,'+
    'getallusersprofiledirectorya,getallusersprofiledirectoryw,getaltmonthnames,'+
    'getalttabinfo,getalttabinfoa,getalttabinfow,getancestor,getappliedgpolist,'+
    'getappliedgpolista,getappliedgpolistw,getapppath,getapppathw,getarcdirection,'+
    'getarraycontents,getaspectratiofilterex,getasrthwnd,getasynckeystate,'+
    'getatomname,getatomnamea,getatomnamew,getattribimsgonistg,'+
    'getauditedpermissionsfromacl,getauditedpermissionsfromacla,'+
    'getauditedpermissionsfromaclw,getax,getbestinterface,getbestinterfaceex,'+
    'getbestinterfacefromstack,getbestroute,getbestroutefromstack,getbh,'+
    'getbinarytype,getbinarytypea,getbinarytypew,getbitmapbits,getbitmapdimensionex,'+
    'getbits,getbkcolor,getbkmode,getbl,getboolfromblob,getboundsrect,getbp,'+
    'getbrushorgex,getbuffersize,getbuffertimestamp,getbuffertotalbytescaptured,'+
    'getbuffertotalframescaptured,getbx,getcalendarinfo,getcalendarinfoa,'+
    'getcalendarinfow,getcallinfo,getcapture,getcaptureaddressdb,getcapturecomment,'+
    'getcapturecommentfromfilename,getcaptureinstancedata,getcapturemactype,'+
    'getcapturetimestamp,getcapturetotalframes,getcaretblinktime,getcaretpos,'+
    'getccinstptr,getcf,getch,getcharabcwidths,getcharabcwidthsa,'+
    'getcharabcwidthsfloat,getcharabcwidthsfloata,getcharabcwidthsfloatw,'+
    'getcharabcwidthsi,getcharabcwidthsw,getcharacterplacement,'+
    'getcharacterplacementa,getcharacterplacementw,getcharwidth,getcharwidth32,'+
    'getcharwidth32a,getcharwidth32w,getcharwidtha,getcharwidthfloat,'+
    'getcharwidthfloata,getcharwidthfloatw,getcharwidthi,getcharwidthinfo,'+
    'getcharwidthw,getcl,getcl_ex,getclassfile,getclassfileormime,getclassidfromblob,'+
    'getclassinfo,getclassinfoa,getclassinfoex,getclassinfoexa,getclassinfoexw,'+
    'getclassinfow,getclasslong,getclasslonga,getclasslongw,getclassname,'+
    'getclassnamea,getclassnamew,getclassurl,getclassword,getclientcallinfo,'+
    'getclientrect,getclientuserhandle,getclipboarddata,getclipboardformatname,'+
    'getclipboardformatnamea,getclipboardformatnamew,getclipboardowner,'+
    'getclipboardsequencenumber,getclipboardviewer,getclipbox,getclipcursor,'+
    'getcliprgn,getclusterfromgroup,getclusterfromnetinterface,getclusterfromnetwork,'+
    'getclusterfromnode,getclusterfromresource,getclustergroupkey,'+
    'getclustergroupstate,getclusterinformation,getclusterkey,getclusternetinterface,'+
    'getclusternetinterfacekey,getclusternetinterfacestate,getclusternetworkid,'+
    'getclusternetworkkey,getclusternetworkstate,getclusternodeid,getclusternodekey,'+
    'getclusternodestate,getclusternotify,getclusterquorumresource,'+
    'getclusterresourcekey,getclusterresourcenetworkname,getclusterresourcestate,'+
    'getclusterresourcetypekey,getcmminfo,getcoloradjustment,getcolordirectory,'+
    'getcolordirectorya,getcolordirectoryw,getcolorprofileelement,'+
    'getcolorprofileelementtag,getcolorprofilefromhandle,getcolorprofileheader,'+
    'getcolorspace,getcomboboxinfo,getcommandline,getcommandlinea,getcommandlinew,'+
    'getcommconfig,getcommhandle,getcommmask,getcommmodemstatus,getcommproperties,'+
    'getcommshadowmsr,getcommstate,getcommtimeouts,getcompluspackageinstallstatus,'+
    'getcomponentidfromclsspec,getcompressedfilesize,getcompressedfilesizea,'+
    'getcompressedfilesizew,getcomputername,getcomputernamea,getcomputernameex,'+
    'getcomputernameexa,getcomputernameexw,getcomputernamew,getcomputerobjectname,'+
    'getcomputerobjectnamea,getcomputerobjectnamew,getconfigdsname,getconfigparam,'+
    'getconfigparamalloc,getconfigparamallocw,getconfigparamw,getconfigurationname,'+
    'getconfigurationnameslist,getconsolealias,getconsolealiasa,getconsolealiases,'+
    'getconsolealiasesa,getconsolealiaseslength,getconsolealiaseslengtha,'+
    'getconsolealiaseslengthw,getconsolealiasesw,getconsolealiasexes,'+
    'getconsolealiasexesa,getconsolealiasexeslength,getconsolealiasexeslengtha,'+
    'getconsolealiasexeslengthw,getconsolealiasexesw,getconsolealiasw,'+
    'getconsolechartype,getconsolecommandhistory,getconsolecommandhistorya,'+
    'getconsolecommandhistorylength,getconsolecommandhistorylengtha,'+
    'getconsolecommandhistorylengthw,getconsolecommandhistoryw,getconsolecp,'+
    'getconsolecursorinfo,getconsolecursormode,getconsoledisplaymode,'+
    'getconsolefontinfo,getconsolefontsize,getconsolehardwarestate,'+
    'getconsoleinputexename,getconsoleinputexenamea,getconsoleinputexenamew,'+
    'getconsoleinputwaithandle,getconsolekeyboardlayoutname,'+
    'getconsolekeyboardlayoutnamea,getconsolekeyboardlayoutnamew,getconsolemode,'+
    'getconsolenlsmode,getconsoleoutputcp,getconsoleprocesslist,'+
    'getconsolescreenbufferinfo,getconsoleselectioninfo,getconsoletitle,'+
    'getconsoletitlea,getconsoletitlew,getconsolewindow,getconvertstg,getcount,'+
    'getcountcolorprofileelements,getcpfilenamefromregistry,getcpinfo,getcpinfoex,'+
    'getcpinfoexa,getcpinfoexw,getcpsuiuserdata,getcs,getcurrencyformat,'+
    'getcurrencyformata,getcurrencyformatw,getcurrentactctx,getcurrentconsolefont,'+
    'getcurrentdirectory,getcurrentdirectorya,getcurrentdirectoryw,getcurrentfilter,'+
    'getcurrenthwprofile,getcurrenthwprofilea,getcurrenthwprofilew,getcurrentobject,'+
    'getcurrentpositionex,getcurrentpowerpolicies,getcurrentprocess,'+
    'getcurrentprocessid,getcurrentthemename,getcurrentthread,getcurrentthreadid,'+
    'getcurrenttimeinseconds,getcursor,getcursorinfo,getcursorpos,getcwd,getcx,'+
    'getdateformat,getdateformata,getdateformatw,getdbgcell,getdc,getdcbrushcolor,'+
    'getdcex,getdcorgex,getdcpencolor,getddsurfacelocal,getdefaultcommconfig,'+
    'getdefaultcommconfiga,getdefaultcommconfigw,getdefaultprinter,'+
    'getdefaultprintera,getdefaultprinterw,getdefaultsortkeysize,'+
    'getdefaultuserprofiledirectory,getdefaultuserprofiledirectorya,'+
    'getdefaultuserprofiledirectoryw,getdesktopwindow,getdevicecaps,'+
    'getdevicedriverbasename,getdevicedriverbasenamea,getdevicedriverbasenamew,'+
    'getdevicedriverfilename,getdevicedriverfilenamea,getdevicedriverfilenamew,'+
    'getdevicegammaramp,getdeviceid,getdevicepowerstate,getdf,getdh,getdi,'+
    'getdialogbaseunits,getdibcolortable,getdibits,getdiskfreespace,'+
    'getdiskfreespacea,getdiskfreespaceex,getdiskfreespaceexa,getdiskfreespaceexw,'+
    'getdiskfreespacew,getdiskinfoa,getdisplaynamefromadspath,getdl,getdlgctrlid,'+
    'getdlgitem,getdlgitemint,getdlgitemtext,getdlgitemtexta,getdlgitemtextw,'+
    'getdlldirectory,getdlldirectorya,getdlldirectoryw,getdllversion,getdnsrootalias,'+
    'getdocumentbitstg,getdosappname,getdoubleclicktime,getdrivermodulehandle,'+
    'getdrivetype,getdrivetypea,getdrivetypew,getds,getdwordfromblob,getdx,geteax,'+
    'getebp,getebx,getecx,getedi,getedx,geteffectiveclientrect,'+
    'geteffectiverightsfromacl,geteffectiverightsfromacla,geteffectiverightsfromaclw,'+
    'geteflags,getegid,geteip,getenabledprotocols,getendpointinfo,getenhmetafile,'+
    'getenhmetafilea,getenhmetafilebits,getenhmetafiledescription,'+
    'getenhmetafiledescriptiona,getenhmetafiledescriptionw,getenhmetafileheader,'+
    'getenhmetafilepaletteentries,getenhmetafilepixelformat,getenhmetafilew,getenv,'+
    'getenvironmentstrings,getenvironmentstringsa,getenvironmentstringsw,'+
    'getenvironmentvariable,getenvironmentvariablea,getenvironmentvariablew,'+
    'geterrdescription,geterrorinfo,getes,getesi,getesp,getetype,geteuid,'+
    'geteventloginformation,getexitcodeprocess,getexitcodethread,getexpandedname,'+
    'getexpandednamea,getexpandednamew,getexpertfromname,getexpertinfo,'+
    'getexpertstatus,getexplicitentriesfromacl,getexplicitentriesfromacla,'+
    'getexplicitentriesfromaclw,getextendedtcptable,getextendedudptable,'+
    'getextensionversion,getfile,getfileattributes,getfileattributesa,'+
    'getfileattributesex,getfileattributesexa,getfileattributesexw,'+
    'getfileattributesw,getfileinformationbyhandle,getfilenamefrombrowse,'+
    'getfilesecurity,getfilesecuritya,getfilesecurityw,getfilesize,getfilesizeex,'+
    'getfiletime,getfiletitle,getfiletitlea,getfiletitlew,getfiletype,'+
    'getfileversioninfo,getfileversioninfoa,getfileversioninfosize,'+
    'getfileversioninfosizea,getfileversioninfosizew,getfileversioninfow,getfilters,'+
    'getfilterversion,getfirmwareenvironmentvariable,getfirmwareenvironmentvariablea,'+
    'getfirmwareenvironmentvariablew,getfirstservice,getfocus,getfontassocstatus,'+
    'getfontdata,getfontlanguageinfo,getfontresourceinfo,getfontresourceinfow,'+
    'getfontunicoderanges,getforegroundwindow,getform,getforma,getformw,getframe,'+
    'getframecapturehandle,getframedestaddress,getframedstaddressoffset,'+
    'getframefromframehandle,getframelength,getframemacheaderlength,getframemactype,'+
    'getframenumber,getframerecognizedata,getframeroutinginformation,'+
    'getframesourceaddress,getframesrcaddressoffset,getframestoredlength,'+
    'getframetimestamp,getfriendlyifindex,getfs,getfullpathname,getfullpathnamea,'+
    'getfullpathnamew,getfxnaddruv,getfxnaddry,getgeoinfo,getgeoinfoa,getgeoinfow,'+
    'getgid,getglyphindices,getglyphindicesa,getglyphindicesw,getglyphoutline,'+
    'getglyphoutlinea,getglyphoutlinew,getgpolist,getgpolista,getgpolistw,'+
    'getgraphicsmode,getgrgid,getgrnam,getgroupname,getgrouppolicynetworkname,'+
    'getgroups,getgs,getguiresources,getguithreadinfo,gethandlecontext,'+
    'gethandleinformation,gethglobalfromilockbytes,gethglobalfromstream,'+
    'gethookinterface,gethostbyaddr,gethostbyname,gethostname,geticiffilefromfile,'+
    'geticifrwfilefromfile,geticmprofile,geticmprofilea,geticmprofilew,'+
    'geticmpstatistics,geticmpstatisticsex,geticmpstatsfromstack,'+
    'geticmpstatsfromstackex,geticoninfo,getif,getifandlink,getifentry,'+
    'getifentryfromstack,getiftable,getiftablefromstack,getigmplist,'+
    'getimageconfiginformation,getimageunusedheaderbytes,'+
    'getinformationcodeauthzlevel,getinformationcodeauthzlevelw,'+
    'getinformationcodeauthzpolicy,getinformationcodeauthzpolicyw,'+
    'getinheritancesource,getinheritancesourcea,getinheritancesourcew,'+
    'getinputdesktop,getinputstate,getintelregisterspointer,getinterfaceinfo,getip,'+
    'getipaddrtable,getipaddrtablefromstack,getiperrorstring,getipforwardtable,'+
    'getipforwardtablefromstack,getipnettable,getipnettablefromstack,getipstatistics,'+
    'getipstatisticsex,getipstatsfromstack,getipstatsfromstackex,getjob,getjoba,'+
    'getjobattributes,getjobw,getkbcodepage,getkernelobjectsecurity,getkerningpairs,'+
    'getkerningpairsa,getkerningpairsw,getkeyboardlayout,getkeyboardlayoutlist,'+
    'getkeyboardlayoutname,getkeyboardlayoutnamea,getkeyboardlayoutnamew,'+
    'getkeyboardstate,getkeyboardtype,getkeynametext,getkeynametexta,getkeynametextw,'+
    'getkeystate,getlargestconsolewindowsize,getlastactivepopup,getlasterror,'+
    'getlastinputinfo,getlayeredwindowattributes,getlayout,getlengthsid,'+
    'getlinguistlangsize,getlistboxinfo,getllcheaderlength,getlocaldatetime,'+
    'getlocaleinfo,getlocaleinfoa,getlocaleinfow,getlocalmanagedapplicationdata,'+
    'getlocalmanagedapplications,getlocaltime,getlogcolorspace,getlogcolorspacea,'+
    'getlogcolorspacew,getlogicaldrives,getlogicaldrivestrings,'+
    'getlogicaldrivestringsa,getlogicaldrivestringsw,getlogin,getlongpathname,'+
    'getlongpathnamea,getlongpathnamew,getmacaddressfromblob,getmacheaderlength,'+
    'getmailslotinfo,getmanagedapplicationcategories,getmanagedapplications,'+
    'getmapmode,getmappedfilename,getmappedfilenamea,getmappedfilenamew,'+
    'getmaxamountofprotocols,getmaxmimeidbytes,getmenu,getmenubarinfo,'+
    'getmenucheckmarkdimensions,getmenucontexthelpid,getmenudefaultitem,getmenuinfo,'+
    'getmenuitemcount,getmenuitemid,getmenuiteminfo,getmenuiteminfoa,'+
    'getmenuiteminfow,getmenuitemrect,getmenuposfromid,getmenustate,getmenustring,'+
    'getmenustringa,getmenustringw,getmessage,getmessagea,getmessageextrainfo,'+
    'getmessagehook,getmessagepos,getmessagetime,getmessagew,getmetafile,'+
    'getmetafilea,getmetafilebitsex,getmetafilew,getmetargn,getmid,getmiterlimit,'+
    'getmodulebasename,getmodulebasenamea,getmodulebasenamew,getmodulefilename,'+
    'getmodulefilenamea,getmodulefilenameex,getmodulefilenameexa,'+
    'getmodulefilenameexw,getmodulefilenamew,getmodulehandle,getmodulehandlea,'+
    'getmodulehandleex,getmodulehandleexa,getmodulehandleexw,getmodulehandlew,'+
    'getmoduleinformation,getmonitorinfo,getmonitorinfoa,getmonitorinfow,'+
    'getmousemovepointsex,getms,getmsg,getmsw,getmuilanguage,getmultipletrustee,'+
    'getmultipletrusteea,getmultipletrusteeoperation,getmultipletrusteeoperationa,'+
    'getmultipletrusteeoperationw,getmultipletrusteew,getnamebytype,getnamebytypea,'+
    'getnamebytypew,getnamedpipehandlestate,getnamedpipehandlestatea,'+
    'getnamedpipehandlestatew,getnamedpipeinfo,getnamedprofileinfo,'+
    'getnamedsecurityinfo,getnamedsecurityinfoa,getnamedsecurityinfoex,'+
    'getnamedsecurityinfoexa,getnamedsecurityinfoexw,getnamedsecurityinfow,'+
    'getnameinfo,getnameinfow,getnativesysteminfo,getnearestcolor,'+
    'getnearestpaletteindex,getnetbyname,getnetscheduleaccountinformation,'+
    'getnetworkbuffer,getnetworkcallback,getnetworkframe,getnetworkid,getnetworkinfo,'+
    'getnetworkinfofromblob,getnetworkinstancedata,getnetworkparams,'+
    'getnextdlggroupitem,getnextdlgtabitem,getnextfgpolicyrefreshinfo,getnextservice,'+
    'getnextvdmcommand,getnlssectionname,getnodeclusterstate,'+
    'getnppaddressfilterfromblob,getnppblobfromui,getnppblobtable,'+
    'getnppetypesapfilter,getnppmactypeasnumber,getnpppatternfilterfromblob,'+
    'getnpptriggerfromblob,getntmsmediapoolname,getntmsmediapoolnamea,'+
    'getntmsmediapoolnamew,getntmsobjectattribute,getntmsobjectattributea,'+
    'getntmsobjectattributew,getntmsobjectinformation,getntmsobjectinformationa,'+
    'getntmsobjectinformationw,getntmsobjectsecurity,getntmsrequestorder,'+
    'getntmsuioptions,getntmsuioptionsa,getntmsuioptionsw,getnumaavailablememory,'+
    'getnumaavailablememorynode,getnumahighestnodenumber,getnumanodeprocessormask,'+
    'getnumaprocessormap,getnumaprocessornode,getnumberformat,getnumberformata,'+
    'getnumberformatw,getnumberofconsolefonts,getnumberofconsoleinputevents,'+
    'getnumberofconsolemousebuttons,getnumberofeventlogrecords,getnumberofinterfaces,'+
    'getobject,getobjecta,getobjectcontext,getobjectheapsize,getobjecttype,'+
    'getobjectw,getodbcshareddata,getoemcp,getof,getoldesteventlogrecord,'+
    'getoleaccversioninfo,getopencardname,getopencardnamea,getopencardnamew,'+
    'getopenclipboardwindow,getopenfilename,getopenfilenamea,getopenfilenamepreview,'+
    'getopenfilenamepreviewa,getopenfilenameprevieww,getopenfilenamew,'+
    'getoutlinetextmetrics,getoutlinetextmetricsa,getoutlinetextmetricsw,'+
    'getoutlookversion,getoverlappedaccessresults,getoverlappedresult,'+
    'getownermodulefromtcp6entry,getownermodulefromtcpentry,'+
    'getownermodulefromudp6entry,getownermodulefromudpentry,getp3ppolicy,'+
    'getp3prequeststatus,getpaletteentries,getparent,getpath,getpathonly,'+
    'getpathonlyw,getpeername,getperadapterinfo,getpercent,getperformanceinfo,getpf,'+
    'getpgrp,getphrasetable,getpid,getpixel,getpixelformat,getpolyfillmode,getppid,'+
    'getpreviousfgpolicyrefreshinfo,getpreviousprotocoloffsetbyname,getprinter,'+
    'getprintera,getprinterdata,getprinterdataa,getprinterdataex,getprinterdataexa,'+
    'getprinterdataexw,getprinterdataw,getprinterdriver,getprinterdrivera,'+
    'getprinterdriverdirectory,getprinterdriverdirectorya,getprinterdriverdirectoryw,'+
    'getprinterdriverex,getprinterdriverexw,getprinterdriverw,getprinterw,'+
    'getprintprocessordirectory,getprintprocessordirectorya,'+
    'getprintprocessordirectoryw,getpriorityclass,getpriorityclipboardformat,'+
    'getprivateobjectsecurity,getprivateprofileint,getprivateprofileinta,'+
    'getprivateprofileintw,getprivateprofilesection,getprivateprofilesectiona,'+
    'getprivateprofilesectionnames,getprivateprofilesectionnamesa,'+
    'getprivateprofilesectionnamesw,getprivateprofilesectionw,'+
    'getprivateprofilestring,getprivateprofilestringa,getprivateprofilestringw,'+
    'getprivateprofilestruct,getprivateprofilestructa,getprivateprofilestructw,'+
    'getprocaddress,getprocessaffinitymask,getprocessdefaultlayout,'+
    'getprocesshandlecount,getprocessheap,getprocessheaps,getprocessid,'+
    'getprocessimagefilename,getprocessimagefilenamea,getprocessimagefilenamew,'+
    'getprocessiocounters,getprocessmemoryinfo,getprocesspriorityboost,'+
    'getprocessshutdownparameters,getprocesstimes,getprocessversion,'+
    'getprocesswindowstation,getprocessworkingsetsize,getprofileint,getprofileinta,'+
    'getprofileintw,getprofilesdirectory,getprofilesdirectorya,getprofilesdirectoryw,'+
    'getprofilesection,getprofilesectiona,getprofilesectionw,getprofilestring,'+
    'getprofilestringa,getprofilestringw,getprofiletype,getprop,getpropa,getproperty,'+
    'getpropertyinfo,getpropertytext,getpropw,getprotobyname,getprotobynumber,'+
    'getprotocoldescription,getprotocoldescriptiontable,getprotocoldllname,'+
    'getprotocolfromname,getprotocolfromproperty,getprotocolfromprotocolid,'+
    'getprotocolfromtable,getprotocolinfo,getprotocolstartoffset,'+
    'getprotocolstartoffsethandle,getps2colorrenderingdictionary,'+
    'getps2colorrenderingintent,getps2colorspacearray,getpwnam,getpwrcapabilities,'+
    'getpwrdiskspindownrange,getpwuid,getq,getqueuedcompletionstatus,getqueuestatus,'+
    'getrandomrgn,getrasdialoutprotocols,getrasterizercaps,getrawinputbuffer,'+
    'getrawinputdata,getrawinputdeviceinfo,getrawinputdeviceinfoa,'+
    'getrawinputdeviceinfow,getrawinputdevicelist,getrdninfoexternal,'+
    'getreconnectinfo,getrecordinfofromguids,getrecordinfofromtypeinfo,'+
    'getrecordsforlocalname,getreg,getregiondata,getregisteredrawinputdevices,'+
    'getrelabs,getrgnbox,getroletext,getroletexta,getroletextw,getrop2,'+
    'getrttandhopcount,getrunningobjecttable,getsaps,getsavefilename,'+
    'getsavefilenamea,getsavefilenamepreview,getsavefilenamepreviewa,'+
    'getsavefilenameprevieww,getsavefilenamew,getscrollbarinfo,getscrollinfo,'+
    'getscrollpos,getscrollrange,getsecuritydescriptorcontrol,'+
    'getsecuritydescriptordacl,getsecuritydescriptorgroup,'+
    'getsecuritydescriptorlength,getsecuritydescriptorowner,'+
    'getsecuritydescriptorrmcontrol,getsecuritydescriptorsacl,getsecurityinfo,'+
    'getsecurityinfoex,getsecurityinfoexa,getsecurityinfoexw,getsecurityuserinfo,'+
    'getservbyname,getservbyport,getservice,getservicea,getservicedisplayname,'+
    'getservicedisplaynamea,getservicedisplaynamew,getservicekeyname,'+
    'getservicekeynamea,getservicekeynamew,getservicew,getsf,getshellwindow,'+
    'getshortpathname,getshortpathnamea,getshortpathnamew,getshrinkedsize,getsi,'+
    'getsididentifierauthority,getsidlengthrequired,getsidsubauthority,'+
    'getsidsubauthoritycount,getsockname,getsockopt,getsoftwareupdateinfo,getsp,'+
    'getspoolfilehandle,getss,getstandardcolorspaceprofile,'+
    'getstandardcolorspaceprofilea,getstandardcolorspaceprofilew,getstartupinfo,'+
    'getstartupinfoa,getstartupinfow,getstatetext,getstatetexta,getstatetextw,'+
    'getstdhandle,getstockobject,getstretchbltmode,getstringelement,'+
    'getstringelementa,getstringelementw,getstringfromblob,getstringsfromblob,'+
    'getstringtype,getstringtypea,getstringtypeex,getstringtypeexa,getstringtypeexw,'+
    'getstringtypew,getsubmenu,getsurfacefromdc,getsyscolor,getsyscolorbrush,'+
    'getsystemdefaultlangid,getsystemdefaultlcid,getsystemdefaultuilanguage,'+
    'getsystemdirectory,getsystemdirectorya,getsystemdirectoryw,getsysteminfo,'+
    'getsystemmenu,getsystemmetrics,getsystempaletteentries,getsystempaletteuse,'+
    'getsystempath,getsystempowerstatus,getsystemregistryquota,'+
    'getsystemtempdirectory,getsystemtempdirectorya,getsystemtempdirectoryw,'+
    'getsystemtime,getsystemtimeadjustment,getsystemtimeasfiletime,getsystemtimes,'+
    'getsystemwindowsdirectory,getsystemwindowsdirectorya,getsystemwindowsdirectoryw,'+
    'getsystemwow64directory,getsystemwow64directorya,getsystemwow64directoryw,'+
    'gettabbedtextextent,gettabbedtextextenta,gettabbedtextextentw,gettapeparameters,'+
    'gettapeposition,gettapestatus,gettapi16callbackmsg,gettaskvisiblewindow,'+
    'gettcpextable2fromstack,gettcpstatistics,gettcpstatisticsex,'+
    'gettcpstatsfromstack,gettcpstatsfromstackex,gettcptable,gettcptablefromstack,'+
    'gettempfilename,gettempfilenamea,gettempfilenamew,gettemppath,gettemppatha,'+
    'gettemppathw,gettextalign,gettextcharacterextra,gettextcharset,'+
    'gettextcharsetinfo,gettextcolor,gettextextentexpoint,gettextextentexpointa,'+
    'gettextextentexpointi,gettextextentexpointw,gettextextentpoint,'+
    'gettextextentpoint32,gettextextentpoint32a,gettextextentpoint32w,'+
    'gettextextentpointa,gettextextentpointi,gettextextentpointw,gettextface,'+
    'gettextfacea,gettextfacew,gettextinput,gettextmetrics,gettextmetricsa,'+
    'gettextmetricsw,getthemeappproperties,getthemebackgroundcontentrect,'+
    'getthemebackgroundextent,getthemebackgroundregion,getthemebool,getthemecolor,'+
    'getthemedocumentationproperty,getthemeenumvalue,getthemefilename,getthemefont,'+
    'getthemeint,getthemeintlist,getthememargins,getthememetric,getthemepartsize,'+
    'getthemeposition,getthemepropertyorigin,getthemerect,getthemestring,'+
    'getthemesysbool,getthemesyscolor,getthemesyscolorbrush,getthemesysfont,'+
    'getthemesysint,getthemesyssize,getthemesysstring,getthemetextextent,'+
    'getthemetextmetrics,getthreadcontext,getthreaddesktop,getthreadinfo,'+
    'getthreadiopendingflag,getthreadlocale,getthreadpriority,getthreadpriorityboost,'+
    'getthreadselectorentry,getthreadtimes,gettickcount,gettimeformat,gettimeformata,'+
    'gettimeformatw,gettimestampforloadedlibrary,gettimezoneinformation,'+
    'gettitlebarinfo,gettnefstreamcodepage,gettokeninformation,gettopwindow,'+
    'gettraceenableflags,gettraceenablelevel,gettraceloggerhandle,gettrksvrobject,'+
    'gettrusteeform,gettrusteeforma,gettrusteeformw,gettrusteename,gettrusteenamea,'+
    'gettrusteenamew,gettrusteetype,gettrusteetypea,gettrusteetypew,gettypebyname,'+
    'gettypebynamea,gettypebynamew,getudpextable2fromstack,getudpstatistics,'+
    'getudpstatisticsex,getudpstatsfromstack,getudpstatsfromstackex,getudptable,'+
    'getudptablefromstack,getuid,getunidirectionaladapterinfo,getupdaterect,'+
    'getupdatergn,geturlcacheconfiginfo,geturlcacheconfiginfoa,'+
    'geturlcacheconfiginfow,geturlcacheentryinfo,geturlcacheentryinfoa,'+
    'geturlcacheentryinfoex,geturlcacheentryinfoexa,geturlcacheentryinfoexw,'+
    'geturlcacheentryinfow,geturlcachegroupattribute,geturlcachegroupattributea,'+
    'geturlcachegroupattributew,geturlcacheheaderdata,getuserappdatapath,'+
    'getuserappdatapatha,getuserappdatapathw,getuserdefaultlangid,getuserdefaultlcid,'+
    'getuserdefaultuilanguage,getusergeoid,getusername,getusernamea,getusernameex,'+
    'getusernameexa,getusernameexw,getusernamew,getuserobjectinformation,'+
    'getuserobjectinformationa,getuserobjectinformationw,getuserobjectsecurity,'+
    'getuserprofiledirectory,getuserprofiledirectorya,getuserprofiledirectoryw,'+
    'getuserprofiledirfromsid,getuserprofiledirfromsida,getuserprofiledirfromsidw,'+
    'getusersid,getutcdatetime,getvarconversionlocalesetting,'+
    'getvdmcurrentdirectories,getversion,getversionex,getversionexa,getversionexw,'+
    'getversionfromfile,getversionfromfileex,getviewportextex,getviewportorgex,'+
    'getvolumeinformation,getvolumeinformationa,getvolumeinformationw,'+
    'getvolumenameforvolumemountpoint,getvolumenameforvolumemountpointa,'+
    'getvolumenameforvolumemountpointw,getvolumepathname,getvolumepathnamea,'+
    'getvolumepathnamesforvolumename,getvolumepathnamesforvolumenamea,'+
    'getvolumepathnamesforvolumenamew,getvolumepathnamew,getvolumesfromdrive,'+
    'getvolumesfromdrivea,getvolumesfromdrivew,getwin4exceptionlevel,getwindow,'+
    'getwindowcontexthelpid,getwindowdc,getwindowextex,getwindowinfo,getwindowlong,'+
    'getwindowlonga,getwindowlongw,getwindowmodulefilename,getwindowmodulefilenamea,'+
    'getwindowmodulefilenamew,getwindoworgex,getwindowplacement,getwindowrect,'+
    'getwindowrgn,getwindowrgnbox,getwindowsaccountdomainsid,getwindowsdirectory,'+
    'getwindowsdirectorya,getwindowsdirectoryw,getwindowsubclass,getwindowtext,'+
    'getwindowtexta,getwindowtextlength,getwindowtextlengtha,getwindowtextlengthw,'+
    'getwindowtextw,getwindowtheme,getwindowthreadprocessid,getwindowword,'+
    'getwinmetafilebits,getworldtransform,getwowshortcutinfo,getwritewatch,'+
    'getwschanges,getzf,gfxaddgfx,gfxbatchchange,gfxcreategfxfactorieslist,'+
    'gfxcreatezonefactorieslist,gfxdestroydeviceinterfacelist,gfxenumerategfxs,'+
    'gfxlogoff,gfxlogon,gfxmodifygfx,gfxopengfx,gfxremovegfx,glaccum,glalphafunc,'+
    'glaretexturesresident,glarrayelement,glbegin,glbindtexture,glbitmap,glblendfunc,'+
    'glcalllist,glcalllists,glclear,glclearaccum,glclearcolor,glcleardepth,'+
    'glclearindex,glclearstencil,glclipplane,glcolor3b,glcolor3bv,glcolor3d,'+
    'glcolor3dv,glcolor3f,glcolor3fv,glcolor3i,glcolor3iv,glcolor3s,glcolor3sv,'+
    'glcolor3ub,glcolor3ubv,glcolor3ui,glcolor3uiv,glcolor3us,glcolor3usv,glcolor4b,'+
    'glcolor4bv,glcolor4d,glcolor4dv,glcolor4f,glcolor4fv,glcolor4i,glcolor4iv,'+
    'glcolor4s,glcolor4sv,glcolor4ub,glcolor4ubv,glcolor4ui,glcolor4uiv,glcolor4us,'+
    'glcolor4usv,glcolormask,glcolormaterial,glcolorpointer,glcopypixels,'+
    'glcopyteximage1d,glcopyteximage2d,glcopytexsubimage1d,glcopytexsubimage2d,'+
    'glcullface,gldebugentry,gldeletelists,gldeletetextures,gldepthfunc,gldepthmask,'+
    'gldepthrange,gldisable,gldisableclientstate,gldrawarrays,gldrawbuffer,'+
    'gldrawelements,gldrawpixels,gle,gledgeflag,gledgeflagpointer,gledgeflagv,'+
    'glenable,glenableclientstate,glend,glendlist,glevalcoord1d,glevalcoord1dv,'+
    'glevalcoord1f,glevalcoord1fv,glevalcoord2d,glevalcoord2dv,glevalcoord2f,'+
    'glevalcoord2fv,glevalmesh1,glevalmesh2,glevalpoint1,glevalpoint2,'+
    'glfeedbackbuffer,glfinish,glflush,glfogf,glfogfv,glfogi,glfogiv,glfrontface,'+
    'glfrustum,glgenlists,glgentextures,glgetbooleanv,glgetclipplane,glgetdoublev,'+
    'glgeterror,glgetfloatv,glgetintegerv,glgetlightfv,glgetlightiv,glgetmapdv,'+
    'glgetmapfv,glgetmapiv,glgetmaterialfv,glgetmaterialiv,glgetpixelmapfv,'+
    'glgetpixelmapuiv,glgetpixelmapusv,glgetpointerv,glgetpolygonstipple,glgetstring,'+
    'glgettexenvfv,glgettexenviv,glgettexgendv,glgettexgenfv,glgettexgeniv,'+
    'glgetteximage,glgettexlevelparameterfv,glgettexlevelparameteriv,'+
    'glgettexparameterfv,glgettexparameteriv,glhint,glindexd,glindexdv,glindexf,'+
    'glindexfv,glindexi,glindexiv,glindexmask,glindexpointer,glindexs,glindexsv,'+
    'glindexub,glindexubv,glinitnames,glinterleavedarrays,glisenabled,glislist,'+
    'glistexture,gllightf,gllightfv,gllighti,gllightiv,gllightmodelf,gllightmodelfv,'+
    'gllightmodeli,gllightmodeliv,gllinestipple,gllinewidth,gllistbase,'+
    'glloadidentity,glloadmatrixd,glloadmatrixf,glloadname,gllogicop,glmap1d,glmap1f,'+
    'glmap2d,glmap2f,glmapgrid1d,glmapgrid1f,glmapgrid2d,glmapgrid2f,glmaterialf,'+
    'glmaterialfv,glmateriali,glmaterialiv,glmatrixmode,glmfbeginglsblock,'+
    'glmfclosemetafile,glmfendglsblock,glmfendplayback,glmfinitplayback,'+
    'glmfplayglsrecord,glmultmatrixd,glmultmatrixf,glnewlist,glnormal3b,glnormal3bv,'+
    'glnormal3d,glnormal3dv,glnormal3f,glnormal3fv,glnormal3i,glnormal3iv,glnormal3s,'+
    'glnormal3sv,glnormalpointer,globaladdatom,globaladdatoma,globaladdatomw,'+
    'globalalloc,globalcompact,globaldeleteatom,globalfindatom,globalfindatoma,'+
    'globalfindatomw,globalfix,globalflags,globalfree,globalgetatomname,'+
    'globalgetatomnamea,globalgetatomnamew,globalhandle,globallock,'+
    'globalmemorystatus,globalmemorystatusex,globalmutexclearexternal,'+
    'globalmutexrequestexternal,globalrealloc,globalsize,globalunfix,globalunlock,'+
    'globalunwire,globalwire,glortho,glpassthrough,glpixelmapfv,glpixelmapuiv,'+
    'glpixelmapusv,glpixelstoref,glpixelstorei,glpixeltransferf,glpixeltransferi,'+
    'glpixelzoom,glpointsize,glpolygonmode,glpolygonoffset,glpolygonstipple,'+
    'glpopattrib,glpopclientattrib,glpopmatrix,glpopname,glprioritizetextures,'+
    'glpushattrib,glpushclientattrib,glpushmatrix,glpushname,glrasterpos2d,'+
    'glrasterpos2dv,glrasterpos2f,glrasterpos2fv,glrasterpos2i,glrasterpos2iv,'+
    'glrasterpos2s,glrasterpos2sv,glrasterpos3d,glrasterpos3dv,glrasterpos3f,'+
    'glrasterpos3fv,glrasterpos3i,glrasterpos3iv,glrasterpos3s,glrasterpos3sv,'+
    'glrasterpos4d,glrasterpos4dv,glrasterpos4f,glrasterpos4fv,glrasterpos4i,'+
    'glrasterpos4iv,glrasterpos4s,glrasterpos4sv,glreadbuffer,glreadpixels,glrectd,'+
    'glrectdv,glrectf,glrectfv,glrecti,glrectiv,glrects,glrectsv,glrendermode,'+
    'glrotated,glrotatef,glsabortcall,glsappref,glsbegincapture,glsbegingls,'+
    'glsbeginobj,glsbinary,glsblock,glscaled,glscalef,glscallarray,'+
    'glscallarrayincontext,glscallstream,glscaptureflags,glscapturefunc,glschannel,'+
    'glscharubz,glscissor,glscommandapi,glscommandfunc,glscommandstring,glscomment,'+
    'glscontext,glscopystream,glsdatapointer,glsdeletecontext,glsdeletereadprefix,'+
    'glsdeletestream,glsdisplaymapfv,glselectbuffer,glsendcapture,glsendgls,'+
    'glsendobj,glsenumstring,glserror,glsflush,glsgencontext,glsgetallcontexts,'+
    'glsgetcapturedispatchtable,glsgetcaptureexectable,glsgetcaptureflags,'+
    'glsgetcommandalignment,glsgetcommandattrib,glsgetcommandfunc,glsgetconsti,'+
    'glsgetconstiv,glsgetconstubz,glsgetcontextfunc,glsgetcontexti,'+
    'glsgetcontextlistl,glsgetcontextlistubz,glsgetcontextpointer,glsgetcontextubz,'+
    'glsgetcurrentcontext,glsgetcurrenttime,glsgeterror,glsgetglrci,glsgetheaderf,'+
    'glsgetheaderfv,glsgetheaderi,glsgetheaderiv,glsgetheaderubz,glsgetlayerf,'+
    'glsgetlayeri,glsgetopcodecount,glsgetopcodes,glsgetstreamattrib,'+
    'glsgetstreamcrc32,glsgetstreamreadname,glsgetstreamsize,glsgetstreamtype,'+
    'glsglrc,glsglrclayer,glshademodel,glsheaderf,glsheaderfv,glsheaderglrci,'+
    'glsheaderi,glsheaderiv,glsheaderlayerf,glsheaderlayeri,glsheaderubz,'+
    'glsiscontext,glsiscontextstream,glsisextensionsupported,glsisutf8string,glslong,'+
    'glslonghigh,glslonglow,glsnullcommandfunc,glsnumb,glsnumbv,glsnumd,glsnumdv,'+
    'glsnumf,glsnumfv,glsnumi,glsnumiv,glsnuml,glsnumlv,glsnums,glsnumsv,glsnumub,'+
    'glsnumubv,glsnumui,glsnumuiv,glsnumul,glsnumulv,glsnumus,glsnumusv,glspad,'+
    'glspixelsetup,glspixelsetupgen,glsreadfunc,glsreadprefix,glsrequireextension,'+
    'glsswapbuffers,glstencilfunc,glstencilmask,glstencilop,glsucs1toutf8z,'+
    'glsucs2toutf8z,glsucs4toutf8,glsucs4toutf8z,glsucstoutf8z,glsulong,glsulonghigh,'+
    'glsulonglow,glsunreadfunc,glsunsupportedcommand,glsupdatecaptureexectable,'+
    'glsutf8toucs1z,glsutf8toucs2z,glsutf8toucs4,glsutf8toucs4z,glsutf8toucsz,'+
    'glswritefunc,glswriteprefix,gltexcoord1d,gltexcoord1dv,gltexcoord1f,'+
    'gltexcoord1fv,gltexcoord1i,gltexcoord1iv,gltexcoord1s,gltexcoord1sv,'+
    'gltexcoord2d,gltexcoord2dv,gltexcoord2f,gltexcoord2fv,gltexcoord2i,'+
    'gltexcoord2iv,gltexcoord2s,gltexcoord2sv,gltexcoord3d,gltexcoord3dv,'+
    'gltexcoord3f,gltexcoord3fv,gltexcoord3i,gltexcoord3iv,gltexcoord3s,'+
    'gltexcoord3sv,gltexcoord4d,gltexcoord4dv,gltexcoord4f,gltexcoord4fv,'+
    'gltexcoord4i,gltexcoord4iv,gltexcoord4s,gltexcoord4sv,gltexcoordpointer,'+
    'gltexenvf,gltexenvfv,gltexenvi,gltexenviv,gltexgend,gltexgendv,gltexgenf,'+
    'gltexgenfv,gltexgeni,gltexgeniv,glteximage1d,glteximage2d,gltexparameterf,'+
    'gltexparameterfv,gltexparameteri,gltexparameteriv,gltexsubimage1d,'+
    'gltexsubimage2d,gltranslated,gltranslatef,glubegincurve,glubeginpolygon,'+
    'glubeginsurface,glubegintrim,glubuild1dmipmaps,glubuild2dmipmaps,glucylinder,'+
    'gludeletenurbsrenderer,gludeletequadric,gludeletetess,gludisk,gluendcurve,'+
    'gluendpolygon,gluendsurface,gluendtrim,gluerrorstring,gluerrorunicodestringext,'+
    'glugetnurbsproperty,glugetstring,glugettessproperty,gluloadsamplingmatrices,'+
    'glulookat,glunewnurbsrenderer,glunewquadric,glunewtess,glunextcontour,'+
    'glunurbscallback,glunurbscurve,glunurbsproperty,glunurbssurface,gluortho2d,'+
    'glupartialdisk,gluperspective,glupickmatrix,gluproject,glupwlcurve,'+
    'gluquadriccallback,gluquadricdrawstyle,gluquadricnormals,gluquadricorientation,'+
    'gluquadrictexture,gluscaleimage,glusphere,glutessbegincontour,'+
    'glutessbeginpolygon,glutesscallback,glutessendcontour,glutessendpolygon,'+
    'glutessnormal,glutessproperty,glutessvertex,gluunproject,glvertex2d,glvertex2dv,'+
    'glvertex2f,glvertex2fv,glvertex2i,glvertex2iv,glvertex2s,glvertex2sv,glvertex3d,'+
    'glvertex3dv,glvertex3f,glvertex3fv,glvertex3i,glvertex3iv,glvertex3s,'+
    'glvertex3sv,glvertex4d,glvertex4dv,glvertex4f,glvertex4fv,glvertex4i,'+
    'glvertex4iv,glvertex4s,glvertex4sv,glvertexpointer,glviewport,gmtime,'+
    'gopher_find_data,gophercreatelocator,gophercreatelocatora,gophercreatelocatorw,'+
    'gopherfindfirstfile,gopherfindfirstfilea,gopherfindfirstfilew,'+
    'gophergetattribute,gophergetattributea,gophergetattributew,gophergetlocatortype,'+
    'gophergetlocatortypea,gophergetlocatortypew,gopheropenfile,gopheropenfilea,'+
    'gopheropenfilew,gradientfill,graystring,graystringa,graystringw,growobjectheap,'+
    'guidbaseddnsnamefromdsname,haccel_userfree,haccel_usermarshal,haccel_usersize,'+
    'haccel_userunmarshal,halacquiredisplayownership,haladjustresourcelist,'+
    'halallocateadapterchannel,halallocatecommonbuffer,halallocatecrashdumpregisters,'+
    'halallprocessorsstarted,halassignslotresources,halbeginsysteminterrupt,'+
    'halcalibrateperformancecounter,haldisablesysteminterrupt,haldispatchtable,'+
    'haldisplaystring,halenablesysteminterrupt,halendsysteminterrupt,'+
    'halflushcommonbuffer,halfreecommonbuffer,halgetadapter,halgetbusdata,'+
    'halgetbusdatabyoffset,halgetenvironmentvariable,halgetinterruptvector,'+
    'halhandlenmi,halinitializeprocessor,halinitsystem,halmakebeep,'+
    'halprivatedispatchtable,halprocessoridle,halquerydisplayparameters,'+
    'halqueryrealtimeclock,halreaddmacounter,halreportresourceusage,halrequestipi,'+
    'halreturntofirmware,halsetbusdata,halsetbusdatabyoffset,halsetdisplayparameters,'+
    'halsetenvironmentvariable,halsetprofileinterval,halsetrealtimeclock,'+
    'halsettimeincrement,halstartnextprocessor,halstartprofileinterrupt,'+
    'halstopprofileinterrupt,haltranslatebusaddress,'+
    'handle_beginning_of_uncompressed_block,hashdata,hbitmap_userfree,'+
    'hbitmap_usermarshal,hbitmap_usersize,hbitmap_userunmarshal,hbrush_userfree,'+
    'hbrush_usermarshal,hbrush_usersize,hbrush_userunmarshal,'+
    'hcaportallocatecommonbuffer,hcaportallocatememory,hcaportclearallbits,'+
    'hcaportclearbits,hcaportcomparememory,hcaportconnectinterrupt,hcaportcopymemory,'+
    'hcaportfindclearbitsandset,hcaportfreecommonbuffer,hcaportfreememory,'+
    'hcaportinitialize,hcaportinitializebitmap,hcaportmovememory,hcaportprint,'+
    'hcaportqueryadapterregistrydirect,hcaportqueryadapterregistrykey,'+
    'hcaporttranslatevirtualaddress,hcaportzeromemory,hconvdlg,hconvdlgtemplate,'+
    'hd_textfilter,hdc_userfree,hdc_usermarshal,hdc_usersize,hdc_userunmarshal,'+
    'hdcclassinstaller,hditem,headlessdispatch,heap32first,heap32listfirst,'+
    'heap32listnext,heap32next,heapalloc,heapcompact,heapcreate,heapcreatetags,'+
    'heapcreatetagsw,heapdestroy,heapextend,heapfree,heaplock,heapqueryinformation,'+
    'heapquerytag,heapquerytagw,heaprealloc,heapsetinformation,heapsize,heapsummary,'+
    'heapunlock,heapusage,heapvalidate,heapvidmemallocaligned,heapwalk,help,'+
    'helperformatunicodestring,henhmetafile_userfree,henhmetafile_usermarshal,'+
    'henhmetafile_usersize,henhmetafile_userunmarshal,hex_canon,hex_canon2,hex2bin,'+
    'hexdump,hexflip32,hexfrombin,hf2dw,hf2up,hfreedlg,hfreedlgtemplate,'+
    'hglobal_userfree,hglobal_usermarshal,hglobal_usersize,hglobal_userunmarshal,'+
    'hicon_userfree,hicon_usermarshal,hicon_usersize,hicon_userunmarshal,'+
    'hidd_flushqueue,hidd_freepreparseddata,hidd_getattributes,hidd_getconfiguration,'+
    'hidd_getfeature,hidd_gethidguid,hidd_getindexedstring,hidd_getinputreport,'+
    'hidd_getmanufacturerstring,hidd_getmsgenredescriptor,hidd_getnuminputbuffers,'+
    'hidd_getphysicaldescriptor,hidd_getpreparseddata,hidd_getproductstring,'+
    'hidd_getserialnumberstring,hidd_hello,hidd_setconfiguration,hidd_setfeature,'+
    'hidd_setnuminputbuffers,hidd_setoutputreport,hidecaret,hidnotifypresence,'+
    'hidp_freecollectiondescription,hidp_getbuttoncaps,hidp_getcaps,'+
    'hidp_getcollectiondescription,hidp_getdata,hidp_getextendedattributes,'+
    'hidp_getlinkcollectionnodes,hidp_getscaledusagevalue,hidp_getspecificbuttoncaps,'+
    'hidp_getspecificvaluecaps,hidp_getusages,hidp_getusagesex,hidp_getusagevalue,'+
    'hidp_getusagevaluearray,hidp_getvaluecaps,hidp_initializereportforid,'+
    'hidp_maxdatalistlength,hidp_maxusagelistlength,hidp_setdata,'+
    'hidp_setscaledusagevalue,hidp_setusages,hidp_setusagevalue,'+
    'hidp_setusagevaluearray,hidp_syspowercaps,hidp_syspowerevent,'+
    'hidp_translateusageandpagestoi8042scancodes,hidp_translateusagestoi8042scancodes,'+
    'hidp_unsetusages,hidp_usageandpagelistdifference,hidp_usagelistdifference,'+
    'hidregisterminidriver,hidservinstaller,highcontrast,hilitemenuitem,'+
    'himagelist_queryinterface,hittestthemebackground,hkoleregisterobject,hlinkclone,'+
    'hlinkcreatebrowsecontext,hlinkcreateextensionservices,hlinkcreatefromdata,'+
    'hlinkcreatefrommoniker,hlinkcreatefromstring,hlinkcreateshortcut,'+
    'hlinkcreateshortcutfrommoniker,hlinkcreateshortcutfromstring,'+
    'hlinkgetspecialreference,hlinkgetvaluefromparams,hlinkgoback,hlinkgoforward,'+
    'hlinkisshortcut,hlinknavigate,hlinknavigatemoniker,hlinknavigatestring,'+
    'hlinknavigatetostringreference,hlinkonnavigate,hlinkonrenamedocument,'+
    'hlinkparsedisplayname,hlinkpreprocessmoniker,hlinkquerycreatefromdata,'+
    'hlinkresolvemonikerfordata,hlinkresolveshortcut,hlinkresolveshortcuttomoniker,'+
    'hlinkresolveshortcuttostring,hlinkresolvestringfordata,hlinksetspecialreference,'+
    'hlinksimplenavigatetomoniker,hlinksimplenavigatetostring,hlinktranslateurl,'+
    'hlinkupdatestackitem,hmenu_userfree,hmenu_usermarshal,hmenu_usersize,'+
    'hmenu_userunmarshal,hmetafile_userfree,hmetafile_usermarshal,hmetafile_usersize,'+
    'hmetafile_userunmarshal,hmetafilepict_userfree,hmetafilepict_usermarshal,'+
    'hmetafilepict_usersize,hmetafilepict_userunmarshal,host_com_close,'+
    'host_createthread,host_direct_access_error,host_exitthread,host_simulate,hour,'+
    'hpalette_userfree,hpalette_usermarshal,hpalette_usersize,hpalette_userunmarshal,'+
    'hraddcolumns,hraddcolumnsex,hrallocadvisesink,hrcomposeeid,hrcomposemsgid,'+
    'hrdecomposeeid,hrdecomposemsgid,hrdispatchnotifications,hrentryidfromsz,'+
    'hrgetomiprovidersflags,hrgetoneprop,hristoragefromstream,hrqueryallrows,'+
    'hrsetomiprovidersflagsinvalid,hrsetoneprop,hrszfromentryid,'+
    'hrthisthreadadvisesink,hrvalidateipmsubtree,hrvalidateparameters,'+
    'ht_computergbgammatable,ht_get8bppformatpalette,ht_get8bppmaskpalette,htodw,'+
    'htonl,htons,httpaddrequestheaders,httpaddrequestheadersa,httpaddrequestheadersw,'+
    'httpcheckdavcompliance,httpcheckdavcompliancea,httpcheckdavcompliancew,'+
    'httpendrequest,httpendrequesta,httpendrequestw,httpextensionproc,httpfilterproc,'+
    'httpopenrequest,httpopenrequesta,httpopenrequestw,httpqueryinfo,httpqueryinfoa,'+
    'httpqueryinfow,httpsendrequest,httpsendrequesta,httpsendrequestex,'+
    'httpsendrequestexa,httpsendrequestexw,httpsendrequestw,httpsfinalprov,huftbuild,'+
    'hwnd_userfree,hwnd_usermarshal,hwnd_usersize,hwnd_userunmarshal,'+
    'i_browserdebugtrace,i_browserqueryotherdomains,i_browserquerystatistics,'+
    'i_browserresetnetlogonstate,i_browserresetstatistics,i_browserserverenum,'+
    'i_cryptcatadminmigratetonewcatdb,i_cryptuiprotect,i_cryptuiprotectfailure,'+
    'i_dscheckbackuplogs,i_dsrestore,i_dsrestorew,i_getdefaultentrysyntax,'+
    'i_netdfsmanagerreportsiteinfo,i_netlogoncontrol,i_netlogoncontrol2,'+
    'i_netserverpasswordget,i_netserverpasswordset2,i_netwkstaresetdfscache,'+
    'i_rpcabortasynccall,i_rpcallocate,i_rpcasyncabortcall,i_rpcasyncsethandle,'+
    'i_rpcbcacheallocate,i_rpcbcachefree,i_rpcbindingcopy,'+
    'i_rpcbindinghandletoasynchandle,i_rpcbindinginqconnid,'+
    'i_rpcbindinginqdynamicendpoint,i_rpcbindinginqdynamicendpointa,'+
    'i_rpcbindinginqdynamicendpointw,i_rpcbindinginqlocalclientpid,'+
    'i_rpcbindinginqsecuritycontext,i_rpcbindinginqtransporttype,'+
    'i_rpcbindinginqwireidforsnego,i_rpcbindingisclientlocal,'+
    'i_rpcbindingtostaticstringbinding,i_rpcbindingtostaticstringbindingw,'+
    'i_rpcclearmutex,i_rpcconnectioninqsockbuffsize,i_rpcconnectionsetsockbuffsize,'+
    'i_rpcdeletemutex,i_rpcenablewmitrace,i_rpcexceptionfilter,i_rpcfree,'+
    'i_rpcfreebuffer,i_rpcfreepipebuffer,i_rpcgetbuffer,i_rpcgetbufferwithobject,'+
    'i_rpcgetcurrentcallhandle,i_rpcgetextendederror,i_rpcifinqtransfersyntaxes,'+
    'i_rpclogevent,i_rpcmapwin32status,i_rpcnegotiatetransfersyntax,'+
    'i_rpcnsbindingsetentryname,i_rpcnsbindingsetentrynamea,'+
    'i_rpcnsbindingsetentrynamew,i_rpcnsgetbuffer,i_rpcnsinterfaceexported,'+
    'i_rpcnsinterfaceunexported,i_rpcnsnegotiatetransfersyntax,i_rpcnsraiseexception,'+
    'i_rpcnssendreceive,i_rpcparsesecurity,i_rpcpauseexecution,'+
    'i_rpcreallocpipebuffer,i_rpcrebindbuffer,i_rpcreceive,i_rpcrequestmutex,'+
    'i_rpcsend,i_rpcsendreceive,i_rpcserverallocateipport,'+
    'i_rpcservercheckclientrestriction,i_rpcserverinqaddresschangefn,'+
    'i_rpcserverinqlocalconnaddress,i_rpcserverinqtransporttype,'+
    'i_rpcserverregisterforwardfunction,i_rpcserversetaddresschangefn,'+
    'i_rpcserveruseprotseq2,i_rpcserveruseprotseq2a,i_rpcserveruseprotseq2w,'+
    'i_rpcserveruseprotseqep2,i_rpcserveruseprotseqep2a,i_rpcserveruseprotseqep2w,'+
    'i_rpcsessionstrictcontexthandle,i_rpcsetasynchandle,i_rpcssdontserializecontext,'+
    'i_rpcsystemfunction001,i_rpctransconnectionallocatepacket,'+
    'i_rpctransconnectionfreepacket,i_rpctransconnectionreallocpacket,'+
    'i_rpctransdatagramallocate,i_rpctransdatagramallocate2,i_rpctransdatagramfree,'+
    'i_rpctransgetthreadevent,i_rpctransiocancelled,i_rpctransservernewconnection,'+
    'i_rpcturnoneeinfopropagation,i_scissecurityprocess,i_scpnpgetservicename,'+
    'i_scsendtsmessage,i_scsetservicebits,i_scsetservicebitsa,i_scsetservicebitsw,'+
    'i_systemfocusdialog,i_uuidcreate,icclose,iccompress,iccompressorchoose,'+
    'iccompressorfree,icdecompress,icdraw,icdrawbegin,icgetdisplayformat,icgetinfo,'+
    'icimagecompress,icimagedecompress,icinfo,icinstall,iclocate,icmp6createfile,'+
    'icmp6parsereplies,icmp6sendecho2,icmpclosehandle,icmpcreatefile,'+
    'icmpparsereplies,icmpsendecho,icmpsendecho2,icmthunk32,iconinfoex,icopen,'+
    'icopenfunction,icremove,icsendmessage,icseqcompressframe,icseqcompressframeend,'+
    'icseqcompressframestart,identifycodeauthzlevel,identifycodeauthzlevelw,'+
    'identifymimetype,identifyntmsslot,igetvalidfontsize,iid_iavieditstream,'+
    'iid_iavifile,iid_iavistream,iid_iclassadmin,iid_igetframe,iidfromstring,'+
    'ilappendid,ilclone,ilclonefirst,ilcombine,ilcreatefrompath,ilcreatefrompatha,'+
    'ilcreatefrompathw,ilfindchild,ilfindlastid,ilfree,ilgetnext,ilgetsize,ilisequal,'+
    'ilisparent,illoadfromstream,ilremovelastid,ilsavetostream,imageaddcertificate,'+
    'imagedirectoryentrytodata,imagedirectoryentrytodataex,'+
    'imageenumeratecertificates,imagegetcertificatedata,imagegetcertificateheader,'+
    'imagegetdigeststream,imagehlpapiversion,imagehlpapiversionex,imagelist_add,'+
    'imagelist_addicon,imagelist_addmasked,imagelist_begindrag,imagelist_copy,'+
    'imagelist_create,imagelist_destroy,imagelist_dragenter,imagelist_dragleave,'+
    'imagelist_dragmove,imagelist_dragshownolock,imagelist_draw,imagelist_drawex,'+
    'imagelist_drawindirect,imagelist_duplicate,imagelist_enddrag,'+
    'imagelist_getbkcolor,imagelist_getdragimage,imagelist_geticon,'+
    'imagelist_geticonsize,imagelist_getimagecount,imagelist_getimageinfo,'+
    'imagelist_getimagerect,imagelist_loadimage,imagelist_loadimagea,'+
    'imagelist_loadimagew,imagelist_merge,imagelist_read,imagelist_readex,'+
    'imagelist_remove,imagelist_replace,imagelist_replaceicon,imagelist_setbkcolor,'+
    'imagelist_setdragcursorimage,imagelist_setfilter,imagelist_setflags,'+
    'imagelist_seticonsize,imagelist_setimagecount,imagelist_setoverlayimage,'+
    'imagelist_write,imagelist_writeex,imageload,imagentheader,'+
    'imageremovecertificate,imagervatosection,imagervatova,imageunload,'+
    'immassociatecontext,immassociatecontextex,immconfigureime,immconfigureimea,'+
    'immconfigureimew,immcreatecontext,immcreateimcc,immcreatesoftkeyboard,'+
    'immdestroycontext,immdestroyimcc,immdestroysoftkeyboard,immdisableime,'+
    'immdisabletextframeservice,immenuminputcontext,immenumregisterword,'+
    'immenumregisterworda,immenumregisterwordw,immescape,immescapea,immescapew,'+
    'immgeneratemessage,immgetcandidatelist,immgetcandidatelista,'+
    'immgetcandidatelistcount,immgetcandidatelistcounta,immgetcandidatelistcountw,'+
    'immgetcandidatelistw,immgetcandidatewindow,immgetcompositionfont,'+
    'immgetcompositionfonta,immgetcompositionfontw,immgetcompositionstring,'+
    'immgetcompositionstringa,immgetcompositionstringw,immgetcompositionwindow,'+
    'immgetcontext,immgetconversionlist,immgetconversionlista,immgetconversionlistw,'+
    'immgetconversionstatus,immgetdefaultimewnd,immgetdescription,immgetdescriptiona,'+
    'immgetdescriptionw,immgetguideline,immgetguidelinea,immgetguidelinew,'+
    'immgethotkey,immgetimcclockcount,immgetimccsize,immgetimclockcount,'+
    'immgetimefilename,immgetimefilenamea,immgetimefilenamew,immgetimemenuitems,'+
    'immgetimemenuitemsa,immgetimemenuitemsw,immgetopenstatus,immgetproperty,'+
    'immgetregisterwordstyle,immgetregisterwordstylea,immgetregisterwordstylew,'+
    'immgetstatuswindowpos,immgetvirtualkey,imminstallime,imminstallimea,'+
    'imminstallimew,immisime,immisuimessage,immisuimessagea,immisuimessagew,'+
    'immlockimc,immlockimcc,immnotifyime,immregisterword,immregisterworda,'+
    'immregisterwordw,immreleasecontext,immrequestmessage,immrequestmessagea,'+
    'immrequestmessagew,immresizeimcc,immsetcandidatewindow,immsetcompositionfont,'+
    'immsetcompositionfonta,immsetcompositionfontw,immsetcompositionstring,'+
    'immsetcompositionstringa,immsetcompositionstringw,immsetcompositionwindow,'+
    'immsetconversionstatus,immsethotkey,immsetopenstatus,immsetstatuswindowpos,'+
    'immshowsoftkeyboard,immsimulatehotkey,immunlockimc,immunlockimcc,'+
    'immunregisterword,immunregisterworda,immunregisterwordw,'+
    'impersonateanonymoustoken,impersonateanyclient,impersonateddeclientwindow,'+
    'impersonateloggedonuser,impersonatenamedpipeclient,impersonateprinterclient,'+
    'impersonatesecuritycontext,impersonateself,impgetime,impgetimea,impgetimew,'+
    'importcookiefile,importcookiefilea,importcookiefilew,importntmsdatabase,'+
    'importrsopdata,importsecuritycontext,importsecuritycontexta,'+
    'importsecuritycontextw,impqueryime,impqueryimea,impqueryimew,impsetime,'+
    'impsetimea,impsetimew,inbvacquiredisplayownership,inbvcheckdisplayownership,'+
    'inbvdisplaystring,inbvenablebootdriver,inbvenabledisplaystring,'+
    'inbvinstalldisplaystringfilter,inbvisbootdriverinstalled,'+
    'inbvnotifydisplayownershiplost,inbvresetdisplay,inbvsetscrollregion,'+
    'inbvsettextcolor,inbvsolidcolorfill,incrementurlcacheheaderdata,inet_addr,'+
    'inet_network,inet_ntoa,infdump,inflateblock,inflatecodes,inflatedynamic,'+
    'inflatefixed,inflaterect,inflatestored,infohook,init_block,'+
    'init_compressed_output_buffer,init_compression_memory,init_decoder_input,'+
    'init_decoder_translation,initatomtable,initcfheader,initcommarg,'+
    'initcommoncontrols,initcommoncontrolsex,initdecoder,initfixed,initfolder,'+
    'initialise_decoder_bitbuf,initializeacl,initializeciisapiperformancedata,'+
    'initializeciperformancedata,initializecriticalsection,'+
    'initializecriticalsectionandspincount,initializeexpression,'+
    'initializefilterperformancedata,initializeflatsb,initializeias,'+
    'initializemonitor,initializepattern,initializeprocessforwswatch,'+
    'initializeprofiles,initializerouter,initializesecuritycontext,'+
    'initializesecuritycontexta,initializesecuritycontextw,'+
    'initializesecuritydescriptor,initializesetuplog,initializesid,'+
    'initializeslisthead,initializeuserprofile,initiatesystemshutdown,'+
    'initiatesystemshutdowna,initiatesystemshutdownex,initiatesystemshutdownexa,'+
    'initiatesystemshutdownexw,initiatesystemshutdownw,initmuilanguage,'+
    'initsafebootmode,initsecurityinterface,initsecurityinterfacea,'+
    'initsecurityinterfacew,injectntmscleaner,injectntmsmedia,insendmessage,'+
    'insendmessageex,insertframe,insertintotable,insertmenu,insertmenua,'+
    'insertmenuitem,insertmenuitema,insertmenuitemw,insertmenuw,insq,'+
    'installapplication,installcolorprofile,installcolorprofilea,'+
    'installcolorprofilew,installdevinst,installdevinstex,installfilterhook,'+
    'installhinfsection,installhinfsectiona,installhinfsectionw,installhook,'+
    'installnewdevice,installperfdll,installperfdlla,installperfdllw,'+
    'installprintprocessor,installselecteddevice,installselecteddriver,'+
    'installwindowsnt,installwindowsupdatedriver,instring,intdiv,'+
    'interlockedcompareexchange,interlockeddecrement,interlockedexchange,'+
    'interlockedexchangeadd,interlockedflushslist,interlockedincrement,'+
    'interlockedpopentryslist,interlockedpushentryslist,internal_literal,'+
    'internal_match,internalconfig,internalcreatedeflocation,'+
    'internalcreateipforwardentry,internalcreateipnetentry,'+
    'internaldeleteipforwardentry,internaldeleteipnetentry,internalextracticonlist,'+
    'internalextracticonlista,internalextracticonlistw,internalgetdeviceconfig,'+
    'internalgetiftable,internalgetipaddrtable,internalgetipforwardtable,'+
    'internalgetipnettable,internalgetps2colorrenderingdictionary,'+
    'internalgetps2colorspacearray,internalgetps2csafromlcs,internalgetps2previewcrd,'+
    'internalgettcptable,internalgetudptable,internalgetwindowtext,'+
    'internalnewlocation,internalnewlocationw,internalperformance,'+
    'internalremovelocation,internalrenamelocation,internalrenamelocationw,'+
    'internalsetdeviceconfig,internalsetifentry,internalsetipforwardentry,'+
    'internalsetipnetentry,internalsetipstats,internalsettcpentry,'+
    'internetalgidtostring,internetalgidtostringa,internetalgidtostringw,'+
    'internetattemptconnect,internetautodial,internetautodialcallback,'+
    'internetautodialhangup,internetcanonicalizeurl,internetcanonicalizeurla,'+
    'internetcanonicalizeurlw,internetcheckconnection,internetcheckconnectiona,'+
    'internetcheckconnectionw,internetclearallpersitecookiedecisions,'+
    'internetclosehandle,internetcombineurl,internetcombineurla,internetcombineurlw,'+
    'internetconfirmzonecrossing,internetconfirmzonecrossinga,'+
    'internetconfirmzonecrossingw,internetconnect,internetconnecta,internetconnectw,'+
    'internetcrackurl,internetcrackurla,internetcrackurlw,internetcreateurl,'+
    'internetcreateurla,internetcreateurlw,internetdial,internetdiala,internetdialw,'+
    'internetenumpersitecookiedecision,internetenumpersitecookiedecisiona,'+
    'internetenumpersitecookiedecisionw,interneterrordlg,internetfindnextfile,'+
    'internetfindnextfilea,internetfindnextfilew,internetfortezzacommand,'+
    'internetgetcertbyurla,internetgetconnectedstate,internetgetconnectedstateex,'+
    'internetgetconnectedstateexa,internetgetconnectedstateexw,internetgetcookie,'+
    'internetgetcookiea,internetgetcookieex,internetgetcookieexa,'+
    'internetgetcookieexw,internetgetcookiew,internetgetlastresponseinfo,'+
    'internetgetlastresponseinfoa,internetgetlastresponseinfow,'+
    'internetgetpersitecookiedecision,internetgetpersitecookiedecisiona,'+
    'internetgetpersitecookiedecisionw,internetgoonline,internetgoonlinea,'+
    'internetgoonlinew,internethangup,internetinitializeautoproxydll,'+
    'internetlockrequestfile,internetopen,internetopena,internetopenurl,'+
    'internetopenurla,internetopenurlw,internetopenw,internetquerydataavailable,'+
    'internetqueryfortezzastatus,internetqueryoption,internetqueryoptiona,'+
    'internetqueryoptionw,internetreadfile,internetreadfileex,internetreadfileexa,'+
    'internetreadfileexw,internetsecurityprotocoltostring,'+
    'internetsecurityprotocoltostringa,internetsecurityprotocoltostringw,'+
    'internetsetcookie,internetsetcookiea,internetsetcookieex,internetsetcookieexa,'+
    'internetsetcookieexw,internetsetcookiew,internetsetdialstate,'+
    'internetsetdialstatea,internetsetdialstatew,internetsetfilepointer,'+
    'internetsetoption,internetsetoptiona,internetsetoptionex,internetsetoptionexa,'+
    'internetsetoptionexw,internetsetoptionw,internetsetpersitecookiedecision,'+
    'internetsetpersitecookiedecisiona,internetsetpersitecookiedecisionw,'+
    'internetsetstatuscallback,internetsetstatuscallbacka,internetsetstatuscallbackw,'+
    'internetshowsecurityinfobyurl,internetshowsecurityinfobyurla,'+
    'internetshowsecurityinfobyurlw,internettimefromsystemtime,'+
    'internettimefromsystemtimea,internettimefromsystemtimew,'+
    'internettimetosystemtime,internettimetosystemtimea,internettimetosystemtimew,'+
    'internetunlockrequestfile,internetwritefile,internetwritefileex,'+
    'internetwritefileexa,internetwritefileexw,intersectcliprect,intersectrect,'+
    'intlstreqworker,intlstreqworkera,intlstreqworkerw,intmul,intsqrt,'+
    'invalidateconsoledibits,invalidaterect,invalidatergn,inventoryntmslibrary,'+
    'invertrect,invertrgn,invokeexternalapplicationex,ioacquirecancelspinlock,'+
    'ioacquireremovelockex,ioacquirevpbspinlock,ioadapterobjecttype,'+
    'ioallocateadapterchannel,ioallocatecontroller,ioallocatedriverobjectextension,'+
    'ioallocateerrorlogentry,ioallocateirp,ioallocatemdl,ioallocateworkitem,'+
    'ioassignresources,ioattachdevice,ioattachdevicebypointer,'+
    'ioattachdevicetodevicestack,ioattachdevicetodevicestacksafe,'+
    'iobuildasynchronousfsdrequest,iobuilddeviceiocontrolrequest,iobuildpartialmdl,'+
    'iobuildsynchronousfsdrequest,iocalldriver,iocancelfileopen,iocancelirp,'+
    'iocheckdesiredaccess,iocheckeabuffervalidity,iocheckfunctionaccess,'+
    'iocheckquerysetfileinformation,iocheckquerysetvolumeinformation,'+
    'iocheckquotabuffervalidity,iocheckshareaccess,iocompleterequest,'+
    'ioconnectinterrupt,iocreatecontroller,iocreatedevice,iocreatedisk,'+
    'iocreatedriver,iocreatefile,iocreatefilespecifydeviceobjecthint,'+
    'iocreatenotificationevent,iocreatestreamfileobject,iocreatestreamfileobjectex,'+
    'iocreatestreamfileobjectlite,iocreatesymboliclink,iocreatesynchronizationevent,'+
    'iocreateunprotectedsymboliclink,iocsqinitialize,iocsqinitializeex,'+
    'iocsqinsertirp,iocsqinsertirpex,iocsqremoveirp,iocsqremovenextirp,ioctlsocket,'+
    'iodeletecontroller,iodeletedevice,iodeletedriver,iodeletesymboliclink,'+
    'iodetachdevice,iodevicehandlerobjectsize,iodevicehandlerobjecttype,'+
    'iodeviceobjecttype,iodisconnectinterrupt,iodriverobjecttype,ioenqueueirp,'+
    'ioenumeratedeviceobjectlist,ioenumerateregisteredfilterslist,'+
    'iofastquerynetworkattributes,iofileobjecttype,ioflushadapterbuffers,'+
    'ioforwardandcatchirp,ioforwardirpsynchronously,iofreeadapterchannel,'+
    'iofreecontroller,iofreeerrorlogentry,iofreeirp,iofreemapregisters,iofreemdl,'+
    'iofreeworkitem,iogetattacheddevice,iogetattacheddevicereference,'+
    'iogetbasefilesystemdeviceobject,iogetbootdiskinformation,'+
    'iogetconfigurationinformation,iogetcurrentprocess,iogetdeviceattachmentbaseref,'+
    'iogetdeviceinterfacealias,iogetdeviceinterfaces,iogetdeviceobjectpointer,'+
    'iogetdeviceproperty,iogetdevicetoverify,iogetdiskdeviceobject,iogetdmaadapter,'+
    'iogetdriverobjectextension,iogetfileobjectgenericmapping,iogetinitialstack,'+
    'iogetlowerdeviceobject,iogetrelateddeviceobject,iogetrequestorprocess,'+
    'iogetrequestorprocessid,iogetrequestorsessionid,iogetstacklimits,'+
    'iogettoplevelirp,ioinitializeirp,ioinitializeremovelockex,ioinitializetimer,'+
    'ioinvalidatedevicerelations,ioinvalidatedevicestate,ioisfileoriginremote,'+
    'ioisoperationsynchronous,ioissystemthread,ioisvalidnamegraftingbuffer,'+
    'ioiswdmversionavailable,iomakeassociatedirp,iomaptransfer,'+
    'ioopendeviceinterfaceregistrykey,ioopendeviceregistrykey,iopageread,'+
    'iopcsqcancelroutine,iopnpdeliverservicepowernotification,'+
    'ioquerydevicedescription,ioqueryfiledosdevicename,ioqueryfileinformation,'+
    'ioqueryvolumeinformation,ioqueuethreadirp,ioqueueworkitem,ioraiseharderror,'+
    'ioraiseinformationalharderror,ioreaddisksignature,ioreadoperationcount,'+
    'ioreadpartitiontableex,ioreadtransfercount,ioregisterbootdriverreinitialization,'+
    'ioregisterdeviceinterface,ioregisterdriverreinitialization,ioregisterfilesystem,'+
    'ioregisterfsregistrationchange,ioregisterlastchanceshutdownnotification,'+
    'ioregisterplugplaynotification,ioregistershutdownnotification,'+
    'ioreleasecancelspinlock,ioreleaseremovelockandwaitex,ioreleaseremovelockex,'+
    'ioreleasevpbspinlock,ioremoveshareaccess,ioreportdetecteddevice,'+
    'ioreporthalresourceusage,ioreportresourcefordetection,ioreportresourceusage,'+
    'ioreporttargetdevicechange,ioreporttargetdevicechangeasynchronous,'+
    'iorequestdeviceeject,ioreuseirp,iosetcompletionroutineex,'+
    'iosetdeviceinterfacestate,iosetdevicetoverify,iosetfileorigin,'+
    'iosetharderrororverifydevice,iosetinformation,iosetiocompletion,'+
    'iosetpartitioninformationex,iosetshareaccess,iosetstartioattributes,'+
    'iosetsystempartition,iosetthreadharderrormode,iosettoplevelirp,'+
    'iostartnextpacket,iostartnextpacketbykey,iostartpacket,iostarttimer,'+
    'iostatisticslock,iostoptimer,iosynchronousinvalidatedevicerelations,'+
    'iosynchronouspagewrite,iothreadtoprocess,iotranslatebusaddress,'+
    'iounregisterfilesystem,iounregisterfsregistrationchange,'+
    'iounregisterplugplaynotification,iounregistershutdownnotification,'+
    'ioupdateshareaccess,iovalidatedeviceiocontrolaccess,ioverifypartitiontable,'+
    'ioverifyvolume,iovolumedevicetodosname,iowmiallocateinstanceids,'+
    'iowmideviceobjecttoinstancename,iowmiexecutemethod,iowmihandletoinstancename,'+
    'iowmiopenblock,iowmiqueryalldata,iowmiqueryalldatamultiple,'+
    'iowmiquerysingleinstance,iowmiquerysingleinstancemultiple,'+
    'iowmiregistrationcontrol,iowmisetnotificationcallback,iowmisetsingleinstance,'+
    'iowmisetsingleitem,iowmisuggestinstancename,iowmiwriteevent,'+
    'iowriteerrorlogentry,iowriteoperationcount,iowritepartitiontableex,'+
    'iowritetransfercount,ipaddinterface,ipallocbuff,'+
    'ipdelayedndisreenumeratebindings,ipdelinterface,ipderegisterarp,'+
    'ipdisablesniffer,ipenablesniffer,ipfreebuff,ipgetaddrtype,ipgetbestinterface,'+
    'ipgetinfo,ipinjectpkt,ipproxyndisrequest,ipregisterarp,ipregisterprotocol,'+
    'ipreleaseaddress,iprenewaddress,ipsetipsecstatus,iptostring,iptransmit,'+
    'ipv6disablefirewallhook,ipv6enablefirewallhook,ipv6getbestrouteinfo,'+
    'ipv6obtainpacketdata,ipv6receive,ipv6receivecomplete,ipv6sendcomplete,'+
    'ipxadjustiocompletionparams,ipxcreateadapterconfigurationport,'+
    'ipxdeleteadapterconfigurationport,ipxdoesrouteexist,ipxgetadapterconfig,'+
    'ipxgetadapterlist,ipxgetoverlappedresult,ipxgetqueuedadapterconfigurationstatus,'+
    'ipxgetqueuedcompletionstatus,ipxpostqueuedcompletionstatus,ipxrecvpacket,'+
    'ipxsendpacket,ipxwancreateadapterconfigurationport,ipxwanqueryinactivitytimer,'+
    'ipxwansetadapterconfiguration,isaccelerator,isadminoverrideactive,isalpha,'+
    'isalphanum,isappthemed,isasyncmoniker,isatty,isatty2,isbadboundedstringptr,'+
    'isbadcodeptr,isbadhugereadptr,isbadhugewriteptr,isbadreadptr,isbadstringptr,'+
    'isbadstringptra,isbadstringptrw,isbadwriteptr,iscatalogfile,iscdromfile,'+
    'ischaralpha,ischaralphaa,ischaralphanumeric,ischaralphanumerica,'+
    'ischaralphanumericw,ischaralphaw,ischarlower,ischarlowera,ischarlowerw,'+
    'ischarspace,ischarspacea,ischarspacew,ischarupper,ischaruppera,ischarupperw,'+
    'ischild,isclipboardformatavailable,iscolorprofiletagpresent,iscolorprofilevalid,'+
    'isdaylightsavingtime,isdaytona,isdbcsleadbyte,isdbcsleadbyteex,'+
    'isdebuggerpresent,isdestinationreachable,isdestinationreachablea,'+
    'isdestinationreachablew,isdfspathex,isdialogmessage,isdialogmessagea,'+
    'isdialogmessagew,isdigit,isdlgbuttonchecked,isdomainlegalcookiedomain,'+
    'isdomainlegalcookiedomaina,isdomainlegalcookiedomainw,isequalguid,isguithread,'+
    'ishostinproxybypasslist,ishungappwindow,isiconic,isjitinprogress,isleapyear,'+
    'islfndrive,islfndrivea,islfndrivew,isllcpresent,islocaladdress,islocalcall,'+
    'isloggingenabled,isloggingenableda,isloggingenabledw,islower,'+
    'ismangledrdnexternal,ismenu,isnamedpiperpccall,isnetdrive,isnetworkalive,'+
    'isntadmin,isnumber,isprint,isprocessinjob,isprocessorfeaturepresent,'+
    'isprofilesenabled,ispwrhibernateallowed,ispwrshutdownallowed,'+
    'ispwrsuspendallowed,israwipxenabled,isrectempty,isremotenpp,issheetalreadyup,'+
    'isspace,isstringguid,issyncforegroundpolicyrefresh,issystemresumeautomatic,'+
    'istextunicode,isthemeactive,isthemebackgroundpartiallytransparent,'+
    'isthemedialogtextureenabled,isthemepartdefined,istokenrestricted,'+
    'istokenuntrusted,isupper,isurlcacheentryexpired,isurlcacheentryexpireda,'+
    'isurlcacheentryexpiredw,isuseranadmin,isvalidacl,isvalidcodepage,isvaliddevmode,'+
    'isvaliddevmodea,isvaliddevmodew,isvalidiid,isvalidindex,isvalidinterface,'+
    'isvalidlanguagegroup,isvalidlocale,isvalidptrin,isvalidptrout,'+
    'isvalidsecuritydescriptor,isvalidsid,isvalidsnmpobjectidentifier,'+
    'isvaliduilanguage,isvalidurl,iswctype,iswellknownsid,iswindow,iswindowenabled,'+
    'iswindowunicode,iswindowvisible,iswineventhookinstalled,iswow64process,isxdigit,'+
    'iszoomed,itemcallback,itemwndproc,itoa1,iunknown_addref_proxy,'+
    'iunknown_queryinterface_proxy,iunknown_release_proxy,ivwordbreakproc,'+
    'iwordbreakproc,jetaddcolumn,jetattachdatabase,jetattachdatabase2,'+
    'jetattachdatabasewithstreaming,jetbackup,jetbackupinstance,'+
    'jetbeginexternalbackup,jetbeginexternalbackupinstance,jetbeginsession,'+
    'jetbegintransaction,jetbegintransaction2,jetclosedatabase,jetclosefile,'+
    'jetclosefileinstance,jetclosetable,jetcommittransaction,jetcompact,'+
    'jetcomputestats,jetconvertddl,jetcreatedatabase,jetcreatedatabase2,'+
    'jetcreatedatabasewithstreaming,jetcreateindex,jetcreateindex2,jetcreateinstance,'+
    'jetcreateinstance2,jetcreatetable,jetcreatetablecolumnindex,'+
    'jetcreatetablecolumnindex2,jetdbutilities,jetdefragment,jetdefragment2,'+
    'jetdelete,jetdeletecolumn,jetdeletecolumn2,jetdeleteindex,jetdeletetable,'+
    'jetdetachdatabase,jetdetachdatabase2,jetdupcursor,jetdupsession,'+
    'jetenablemultiinstance,jetendexternalbackup,jetendexternalbackupinstance,'+
    'jetendexternalbackupinstance2,jetendsession,jetenumeratecolumns,jetescrowupdate,'+
    'jetexternalrestore,jetexternalrestore2,jetfreebuffer,jetgetattachinfo,'+
    'jetgetattachinfoinstance,jetgetbookmark,jetgetcolumninfo,jetgetcounter,'+
    'jetgetcurrentindex,jetgetcursorinfo,jetgetdatabasefileinfo,jetgetdatabaseinfo,'+
    'jetgetindexinfo,jetgetinstanceinfo,jetgetlock,jetgetloginfo,'+
    'jetgetloginfoinstance,jetgetloginfoinstance2,jetgetls,jetgetobjectinfo,'+
    'jetgetrecordposition,jetgetsecondaryindexbookmark,jetgetsystemparameter,'+
    'jetgettablecolumninfo,jetgettableindexinfo,jetgettableinfo,'+
    'jetgettruncateloginfoinstance,jetgetversion,jetgotobookmark,jetgotoposition,'+
    'jetgotosecondaryindexbookmark,jetgrowdatabase,jetidle,jetindexrecordcount,'+
    'jetinit,jetinit2,jetinit3,jetintersectindexes,jetmakekey,jetmove,'+
    'jetopendatabase,jetopenfile,jetopenfileinstance,jetopenfilesectioninstance,'+
    'jetopentable,jetopentemptable,jetopentemptable2,jetopentemptable3,'+
    'jetossnapshotfreeze,jetossnapshotprepare,jetossnapshotthaw,'+
    'jetpreparetocommittransaction,jetprepareupdate,jetreadfile,jetreadfileinstance,'+
    'jetregistercallback,jetrenamecolumn,jetrenametable,jetresetcounter,'+
    'jetresetsessioncontext,jetresettablesequential,jetrestore,jetrestore2,'+
    'jetrestoreinstance,jetretrievecolumn,jetretrievecolumns,jetretrievekey,'+
    'jetretrievetaggedcolumnlist,jetrollback,jetseek,jetsetcolumn,'+
    'jetsetcolumndefaultvalue,jetsetcolumns,jetsetcurrentindex,jetsetcurrentindex2,'+
    'jetsetcurrentindex3,jetsetcurrentindex4,jetsetdatabasesize,jetsetindexrange,'+
    'jetsetls,jetsetsessioncontext,jetsetsystemparameter,jetsettablesequential,'+
    'jetsnapshotstart,jetsnapshotstop,jetstopbackup,jetstopbackupinstance,'+
    'jetstopservice,jetstopserviceinstance,jetterm,jetterm2,jettruncatelog,'+
    'jettruncateloginstance,jetunregistercallback,jetupdate,jetupgradedatabase,'+
    'jobrightsmapping,joy32message,joyconfigchanged,joygetdevcaps,joygetdevcapsa,'+
    'joygetdevcapsw,joygetnumdevs,joygetpos,joygetposex,joygetthreshold,'+
    'joyreleasecapture,joysetcapture,joysetthreshold,k32thk1632epilog,'+
    'k32thk1632prolog,kdchangeoption,kdcomportinuse,kddebuggerenabled,'+
    'kddebuggernotpresent,kddisabledebugger,kdenabledebugger,kdentereddebugger,'+
    'kdpollbreakin,kdpowertransition,kdrefreshdebuggernotpresent,'+
    'kdsystemdebugcontrol,ke386callbios,ke386iosetaccessprocess,'+
    'ke386queryioaccessmap,ke386setioaccessmap,keacquireinterruptspinlock,'+
    'keacquirespinlock,keacquirespinlockatdpclevel,keaddsystemservicetable,'+
    'keareallapcsdisabled,keareapcsdisabled,keattachprocess,kebugcheck,kebugcheckex,'+
    'kecanceltimer,kecapturepersistentthreadstate,keclearevent,keconnectinterrupt,'+
    'kedcacheflushcount,kedelayexecutionthread,kederegisterbugcheckcallback,'+
    'kederegisterbugcheckreasoncallback,kederegisternmicallback,kedetachprocess,'+
    'kedisconnectinterrupt,keentercriticalregion,keenterguardedregion,'+
    'keenterkerneldebugger,kefindconfigurationentry,kefindconfigurationnextentry,'+
    'keflushentiretb,keflushqueueddpcs,keflushwritebuffer,kegenericcalldpc,'+
    'kegetcurrentirql,kegetcurrentthread,kegetpreviousmode,'+
    'kegetrecommendedshareddataalignment,kei386abioscall,kei386allocategdtselectors,'+
    'kei386call16bitcstylefunction,kei386call16bitfunction,kei386flattogdtselector,'+
    'kei386getlid,kei386machinetype,kei386releasegdtselectors,kei386releaselid,'+
    'kei386setgdtselector,keicacheflushcount,keinitializeapc,'+
    'keinitializecrashdumpheader,keinitializedevicequeue,keinitializedpc,'+
    'keinitializeevent,keinitializeinterrupt,keinitializemutant,keinitializemutex,'+
    'keinitializequeue,keinitializesemaphore,keinitializespinlock,'+
    'keinitializethreadeddpc,keinitializetimer,keinitializetimerex,'+
    'keinsertbykeydevicequeue,keinsertdevicequeue,keinsertheadqueue,keinsertqueue,'+
    'keinsertqueueapc,keinsertqueuedpc,keinvalidateallcaches,keipigenericcall,'+
    'keisattachedprocess,keisexecutingdpc,keiswaitlistempty,keleavecriticalregion,'+
    'keleaveguardedregion,keloaderblock,kelowerirql,kenumberprocessors,'+
    'keprofileinterrupt,keprofileinterruptwithsource,kepulseevent,'+
    'kequeryactiveprocessors,kequeryinterrupttime,kequeryperformancecounter,'+
    'kequeryprioritythread,kequeryruntimethread,kequerysystemtime,kequerytickcount,'+
    'kequerytimeincrement,keraiseirql,keraiseirqltodpclevel,keraiseirqltosynchlevel,'+
    'keraiseuserexception,kereadstateevent,kereadstatemutant,kereadstatemutex,'+
    'kereadstatequeue,kereadstatesemaphore,kereadstatetimer,'+
    'keregisterbugcheckcallback,keregisterbugcheckreasoncallback,'+
    'keregisternmicallback,kereleaseinterruptspinlock,kereleasemutant,kereleasemutex,'+
    'kereleasesemaphore,kereleasespinlock,kereleasespinlockfromdpclevel,'+
    'keremovebykeydevicequeue,keremovebykeydevicequeueifbusy,keremovedevicequeue,'+
    'keremoveentrydevicequeue,keremovequeue,keremovequeuedpc,'+
    'keremovesystemservicetable,keresetevent,kerestorefloatingpointstate,'+
    'kereverttouseraffinitythread,kerundownqueue,kesavefloatingpointstate,'+
    'kesavestateforhibernate,keservicedescriptortable,kesetaffinitythread,'+
    'kesetbaseprioritythread,kesetdmaiocoherency,kesetevent,keseteventboostpriority,'+
    'kesetidealprocessorthread,kesetimportancedpc,kesetkernelstackswapenable,'+
    'kesetprioritythread,kesetprofileirql,kesetsystemaffinitythread,'+
    'kesettargetprocessordpc,kesettimeincrement,kesettimer,kesettimerex,'+
    'kesignalcalldpcdone,kesignalcalldpcsynchronize,kestackattachprocess,'+
    'kestallexecutionprocessor,kesynchronizeexecution,keterminatethread,ketickcount,'+
    'keunstackdetachprocess,keupdateruntime,keupdatesystemtime,keusermodecallback,'+
    'kewaitformultipleobjects,kewaitformutexobject,kewaitforsingleobject,keybd_event,'+
    'keyboardclassinstaller,kibugcheckdata,kicheckforkernelapcdelivery,'+
    'kicoprocessorerror,kideliverapc,kidispatchinterrupt,kienabletimerwatchdog,'+
    'kifastsystemcall,kifastsystemcallret,kiintsystemcall,kiipiserviceroutine,kill,'+
    'killtimer,kiraiseuserexceptiondispatcher,kiunexpectedinterrupt,'+
    'kiuserapcdispatcher,kiusercallbackdispatcher,kiuserexceptiondispatcher,km,'+
    'kocreateinstance,kodeviceinitialize,kodriverinitialize,kol,korelease,kp,'+
    'ksacquirecontrol,ksacquiredevice,ksacquiredevicesecuritylock,'+
    'ksacquireresetvalue,ksadddevice,ksaddevent,ksaddirptocancelablequeue,'+
    'ksadditemtoobjectbag,ksaddobjectcreateitemtodeviceheader,'+
    'ksaddobjectcreateitemtoobjectheader,ksallocatedefaultclock,'+
    'ksallocatedefaultclockex,ksallocatedeviceheader,ksallocateextradata,'+
    'ksallocateobjectbag,ksallocateobjectcreateitem,ksallocateobjectheader,'+
    'kscachemedium,kscancelio,kscancelroutine,kscompletependingrequest,'+
    'kscopyobjectbagitems,kscreateallocator,kscreatebusenumobject,kscreateclock,'+
    'kscreatedefaultallocator,kscreatedefaultallocatorex,kscreatedefaultclock,'+
    'kscreatedefaultsecurity,kscreatedevice,kscreatefilterfactory,kscreatepin,'+
    'kscreatetopologynode,ksdecrementcountedworker,ksdefaultaddeventhandler,'+
    'ksdefaultdeviceiocompletion,ksdefaultdispatchpnp,ksdefaultdispatchpower,'+
    'ksdefaultforwardirp,ksdereferencebusobject,ksdereferencesoftwarebusobject,'+
    'ksdevicegetbusdata,ksdeviceregisteradapterobject,ksdevicesetbusdata,'+
    'ksdisableevent,ksdiscardevent,ksdispatchfastiodevicecontrolfailure,'+
    'ksdispatchfastreadfailure,ksdispatchinvaliddevicerequest,ksdispatchirp,'+
    'ksdispatchquerysecurity,ksdispatchsetsecurity,ksdispatchspecificmethod,'+
    'ksdispatchspecificproperty,ksecregistersecurityprovider,ksecvalidatebuffer,'+
    'ksenableevent,ksenableeventwithallocator,ksfastmethodhandler,'+
    'ksfastpropertyhandler,ksfilteracquireprocessingmutex,'+
    'ksfilteraddtopologyconnections,ksfilterattemptprocessing,ksfiltercreatenode,'+
    'ksfiltercreatepinfactory,ksfilterfactoryaddcreateitem,'+
    'ksfilterfactorygetsymboliclink,ksfilterfactorysetdeviceclassesstate,'+
    'ksfilterfactoryupdatecachedata,ksfiltergetandgate,ksfiltergetchildpincount,'+
    'ksfiltergetfirstchildpin,ksfilterregisterpowercallbacks,'+
    'ksfilterreleaseprocessingmutex,ksforwardandcatchirp,ksforwardirp,'+
    'ksfreedefaultclock,ksfreedeviceheader,ksfreeeventlist,ksfreeobjectbag,'+
    'ksfreeobjectcreateitem,ksfreeobjectcreateitemsbycontext,ksfreeobjectheader,'+
    'ksgeneratedataevent,ksgenerateevent,ksgenerateeventlist,ksgenerateevents,'+
    'ksgetbusenumidentifier,ksgetbusenumparentfdofromchildpdo,'+
    'ksgetbusenumpnpdeviceobject,ksgetdefaultclockstate,ksgetdefaultclocktime,'+
    'ksgetdevice,ksgetdevicefordeviceobject,ksgetfilterfromirp,ksgetfirstchild,'+
    'ksgetimagenameandresourceid,ksgetmediatype,ksgetmediatypecount,'+
    'ksgetmultiplepinfactoryitems,ksgetnextsibling,ksgetnodeidfromirp,'+
    'ksgetobjectfromfileobject,ksgetobjecttypefromfileobject,ksgetobjecttypefromirp,'+
    'ksgetouterunknown,ksgetparent,ksgetpinfromirp,kshandlesizedlistquery,'+
    'ksidefaultclockaddmarkevent,ksincrementcountedworker,ksinitializedevice,'+
    'ksinitializedriver,ksinstallbusenuminterface,'+
    'ksipropertydefaultclockgetcorrelatedphysicaltime'+
    'ksipropertydefaultclockgetcorrelatedtime,ksipropertydefaultclockgetfunctiontable,'+
    'ksipropertydefaultclockgetphysicaltime,ksipropertydefaultclockgetresolution,'+
    'ksipropertydefaultclockgetstate,ksipropertydefaultclockgettime,'+
    'ksiqueryobjectcreateitemspresent,ksisbusenumchilddevice,ksloadresource,'+
    'ksmapmodulename,ksmergeautomationtables,ksmethodhandler,'+
    'ksmethodhandlerwithallocator,ksmoveirpsoncancelablequeue,ksnulldriverunload,'+
    'ksopendefaultdevice,kspinacquireprocessingmutex,kspinattachandgate,'+
    'kspinattachorgate,kspinattemptprocessing,kspindataintersection,kspingetandgate,'+
    'kspingetavailablebytecount,kspingetconnectedfilterinterface,'+
    'kspingetconnectedpindeviceobject,kspingetconnectedpinfileobject,'+
    'kspingetconnectedpininterface,kspingetcopyrelationships,'+
    'kspingetfirstclonestreampointer,kspingetleadingedgestreampointer,'+
    'kspingetnextsiblingpin,kspingetparentfilter,kspingetreferenceclockinterface,'+
    'kspingettrailingedgestreampointer,kspinpropertyhandler,'+
    'kspinregisterframereturncallback,kspinregisterhandshakecallback,'+
    'kspinregisterirpcompletioncallback,kspinregisterpowercallbacks,'+
    'kspinreleaseprocessingmutex,kspinsetpinclocktime,kspinsubmitframe,'+
    'kspinsubmitframemdl,ksprobestreamirp,ksprocesspinupdate,kspropertyhandler,'+
    'kspropertyhandlerwithallocator,ksquerydevicepnpobject,ksqueryinformationfile,'+
    'ksqueryobjectaccessmask,ksqueryobjectcreateitem,ksqueueworkitem,ksreadfile,'+
    'ksrecalculatestackdepth,ksreferencebusobject,ksreferencesoftwarebusobject,'+
    'ksregisteraggregatedclientunknown,ksregistercountedworker,'+
    'ksregisterfilterwithnokspins,ksregisterworker,ksreleasecontrol,ksreleasedevice,'+
    'ksreleasedevicesecuritylock,ksreleaseirponcancelablequeue,'+
    'ksremovebusenuminterface,ksremoveirpfromcancelablequeue,'+
    'ksremoveitemfromobjectbag,ksremovespecificirpfromcancelablequeue,'+
    'ksresolverequiredattributes,ksservicebusenumcreaterequest,'+
    'ksservicebusenumpnprequest,kssetdefaultclockstate,kssetdefaultclocktime,'+
    'kssetdevicepnpandbaseobject,kssetinformationfile,kssetmajorfunctionhandler,'+
    'kssetpowerdispatch,kssettargetdeviceobject,kssettargetstate,ksstreamio,'+
    'ksstreampointeradvance,ksstreampointeradvanceoffsets,'+
    'ksstreampointeradvanceoffsetsandunlock,ksstreampointercanceltimeout,'+
    'ksstreampointerclone,ksstreampointerdelete,ksstreampointergetirp,'+
    'ksstreampointergetmdl,ksstreampointergetnextclone,ksstreampointerlock,'+
    'ksstreampointerscheduletimeout,ksstreampointersetstatuscode,'+
    'ksstreampointerunlock,kssynchronousdevicecontrol,kssynchronousiocontroldevice,'+
    'ksterminatedevice,kstopologypropertyhandler,ksunregisterworker,'+
    'ksunserializeobjectpropertiesfromregistry,ksvalidateallocatorcreaterequest,'+
    'ksvalidateallocatorframingex,ksvalidateclockcreaterequest,'+
    'ksvalidateconnectrequest,ksvalidatetopologynodecreaterequest,kswritefile,'+
    'laddrparamsinited,launchinfsection,launchinfsectionex,launchwizard,lbitemfrompt,'+
    'lcmapstring,lcmapstringa,lcmapstringw,ldap_abandon,ldap_add,ldap_add_ext,'+
    'ldap_add_ext_s,ldap_add_ext_sa,ldap_add_ext_sw,ldap_add_exta,ldap_add_extw,'+
    'ldap_add_s,ldap_add_sa,ldap_add_sw,ldap_adda,ldap_addw,ldap_bind,ldap_bind_s,'+
    'ldap_bind_sa,ldap_bind_sw,ldap_binda,ldap_bindw,ldap_check_filter,'+
    'ldap_check_filtera,ldap_check_filterw,ldap_cleanup,ldap_close_extended_op,'+
    'ldap_compare,ldap_compare_ext,ldap_compare_ext_s,ldap_compare_ext_sa,'+
    'ldap_compare_ext_sw,ldap_compare_exta,ldap_compare_extw,ldap_compare_s,'+
    'ldap_compare_sa,ldap_compare_sw,ldap_comparea,ldap_comparew,ldap_conn_from_msg,'+
    'ldap_connect,ldap_control_free,ldap_control_freea,ldap_control_freew,'+
    'ldap_controls_free,ldap_controls_freea,ldap_controls_freew,ldap_count_entries,'+
    'ldap_count_references,ldap_count_values,ldap_count_values_len,'+
    'ldap_count_valuesa,ldap_count_valuesw,ldap_create_page_control,'+
    'ldap_create_page_controla,ldap_create_page_controlw,ldap_create_sort_control,'+
    'ldap_create_sort_controla,ldap_create_sort_controlw,ldap_create_vlv_control,'+
    'ldap_create_vlv_controla,ldap_create_vlv_controlw,ldap_delete,ldap_delete_ext,'+
    'ldap_delete_ext_s,ldap_delete_ext_sa,ldap_delete_ext_sw,ldap_delete_exta,'+
    'ldap_delete_extw,ldap_delete_s,ldap_delete_sa,ldap_delete_sw,ldap_deletea,'+
    'ldap_deletew,ldap_dn2ufn,ldap_dn2ufna,ldap_dn2ufnw,ldap_encode_sort_control,'+
    'ldap_encode_sort_controla,ldap_encode_sort_controlw,ldap_err2string,'+
    'ldap_err2stringa,ldap_err2stringw,ldap_escape_filter_element,'+
    'ldap_escape_filter_elementa,ldap_escape_filter_elementw,ldap_explode_dn,'+
    'ldap_explode_dna,ldap_explode_dnw,ldap_extended_operation,'+
    'ldap_extended_operation_s,ldap_extended_operation_sa,ldap_extended_operation_sw,'+
    'ldap_extended_operationa,ldap_extended_operationw,ldap_first_attribute,'+
    'ldap_first_attributea,ldap_first_attributew,ldap_first_entry,'+
    'ldap_first_reference,ldap_free_controls,ldap_free_controlsa,ldap_free_controlsw,'+
    'ldap_get_dn,ldap_get_dna,ldap_get_dnw,ldap_get_next_page,ldap_get_next_page_s,'+
    'ldap_get_option,ldap_get_optiona,ldap_get_optionw,ldap_get_paged_count,'+
    'ldap_get_values,ldap_get_values_len,ldap_get_values_lena,ldap_get_values_lenw,'+
    'ldap_get_valuesa,ldap_get_valuesw,ldap_init,ldap_inita,ldap_initw,ldap_memfree,'+
    'ldap_memfreea,ldap_memfreew,ldap_modify,ldap_modify_ext,ldap_modify_ext_s,'+
    'ldap_modify_ext_sa,ldap_modify_ext_sw,ldap_modify_exta,ldap_modify_extw,'+
    'ldap_modify_s,ldap_modify_sa,ldap_modify_sw,ldap_modifya,ldap_modifyw,'+
    'ldap_modrdn,ldap_modrdn_s,ldap_modrdn_sa,ldap_modrdn_sw,ldap_modrdn2,'+
    'ldap_modrdn2_s,ldap_modrdn2_sa,ldap_modrdn2_sw,ldap_modrdn2a,ldap_modrdn2w,'+
    'ldap_modrdna,ldap_modrdnw,ldap_msgfree,ldap_next_attribute,ldap_next_attributea,'+
    'ldap_next_attributew,ldap_next_entry,ldap_next_reference,ldap_open,ldap_opena,'+
    'ldap_openw,ldap_parse_extended_result,ldap_parse_extended_resulta,'+
    'ldap_parse_extended_resultw,ldap_parse_page_control,ldap_parse_page_controla,'+
    'ldap_parse_page_controlw,ldap_parse_reference,ldap_parse_referencea,'+
    'ldap_parse_referencew,ldap_parse_result,ldap_parse_resulta,ldap_parse_resultw,'+
    'ldap_parse_sort_control,ldap_parse_sort_controla,ldap_parse_sort_controlw,'+
    'ldap_parse_vlv_control,ldap_parse_vlv_controla,ldap_parse_vlv_controlw,'+
    'ldap_perror,ldap_rename_ext,ldap_rename_ext_s,ldap_rename_ext_sa,'+
    'ldap_rename_ext_sw,ldap_rename_exta,ldap_rename_extw,ldap_result,'+
    'ldap_result2error,ldap_sasl_bind,ldap_sasl_bind_s,ldap_sasl_bind_sa,'+
    'ldap_sasl_bind_sw,ldap_sasl_binda,ldap_sasl_bindw,ldap_search,'+
    'ldap_search_abandon_page,ldap_search_ext,ldap_search_ext_s,ldap_search_ext_sa,'+
    'ldap_search_ext_sw,ldap_search_exta,ldap_search_extw,ldap_search_init_page,'+
    'ldap_search_init_pagea,ldap_search_init_pagew,ldap_search_s,ldap_search_sa,'+
    'ldap_search_st,ldap_search_sta,ldap_search_stw,ldap_search_sw,ldap_searcha,'+
    'ldap_searchw,ldap_set_dbg_flags,ldap_set_dbg_routine,ldap_set_option,'+
    'ldap_set_optiona,ldap_set_optionw,ldap_simple_bind,ldap_simple_bind_s,'+
    'ldap_simple_bind_sa,ldap_simple_bind_sw,ldap_simple_binda,ldap_simple_bindw,'+
    'ldap_sslinit,ldap_sslinita,ldap_sslinitw,ldap_start_tls_s,ldap_start_tls_sa,'+
    'ldap_start_tls_sw,ldap_startup,ldap_stop_tls_s,ldap_ufn2dn,ldap_ufn2dna,'+
    'ldap_ufn2dnw,ldap_unbind,ldap_unbind_s,ldap_value_free,ldap_value_freea,'+
    'ldap_value_freew,ldapgetlasterror,ldapmaperrortowin32,ldapunicodetoutf8,'+
    'ldaputf8tounicode,ldraccessoutofprocessresource,ldraccessresource,ldraddrefdll,'+
    'ldralternateresourcesenabled,ldrcreateoutofprocessimage,'+
    'ldrdestroyoutofprocessimage,ldrdisablethreadcalloutsfordll,'+
    'ldrenumerateloadedmodules,ldrenumresources,ldrfindcreateprocessmanifest,'+
    'ldrfindentryforaddress,ldrfindresource_u,ldrfindresourcedirectory_u,'+
    'ldrfindresourceex_u,ldrflushalternateresourcemodules,ldrgetdllhandle,'+
    'ldrgetdllhandleex,ldrgetprocedureaddress,ldrhotpatchroutine,ldrinitializethunk,'+
    'ldrinitshimenginedynamic,ldrloadalternateresourcemodule,ldrloaddll,'+
    'ldrlockloaderlock,ldrprocessrelocationblock,ldrqueryimagefileexecutionoptions,'+
    'ldrqueryprocessmoduleinformation,ldrsetappcompatdllredirectioncallback,'+
    'ldrsetdllmanifestprober,ldrshutdownprocess,ldrshutdownthread,'+
    'ldrunloadalternateresourcemodule,ldrunloaddll,ldrunlockloaderlock,'+
    'ldrverifyimagematcheschecksum,leactivate,leavecriticalpolicysection,'+
    'leavecriticalsection,leaveuserprofilelock,lechangedata,leclone,leclose,lecopy,'+
    'lecopyfromlink,lecreateinvisible,ledraw,leenumformat,leequal,leexecute,'+
    'legacydriverproppageprovider,legetdata,legetupdateoptions,leobjectconvert,'+
    'leobjectlong,lequerybounds,lequeryopen,lequeryoutofdate,lequeryprotocol,'+
    'lequerytype,lereconnect,lerelease,lesavetostream,lesetbounds,lesetdata,'+
    'lesethostnames,lesettargetdevice,lesetupdateoptions,leshow,leupdate,lfcnt,'+
    'lhashvalofnamesysa,libmain,line,lineaccept,lineaddprovider,lineaddprovidera,'+
    'lineaddproviderw,lineaddtoconference,lineagentspecific,lineanswer,'+
    'lineblindtransfer,lineblindtransfera,lineblindtransferw,lineclose,'+
    'linecompletecall,linecompletetransfer,lineconfigdialog,lineconfigdialoga,'+
    'lineconfigdialogedit,lineconfigdialogedita,lineconfigdialogeditw,'+
    'lineconfigdialogw,lineconfigprovider,linecopyfast,linecreateagent,'+
    'linecreateagenta,linecreateagentsession,linecreateagentsessiona,'+
    'linecreateagentsessionw,linecreateagentw,linedda,linedeallocatecall,'+
    'linedevspecific,linedevspecificfeature,linedial,linediala,linedialw,linedrop,'+
    'lineforward,lineforwarda,lineforwardw,linegatherdigits,linegatherdigitsa,'+
    'linegatherdigitsw,linegeneratedigits,linegeneratedigitsa,linegeneratedigitsw,'+
    'linegeneratetone,linegetaddresscaps,linegetaddresscapsa,linegetaddresscapsw,'+
    'linegetaddressid,linegetaddressida,linegetaddressidw,linegetaddressstatus,'+
    'linegetaddressstatusa,linegetaddressstatusw,linegetagentactivitylist,'+
    'linegetagentactivitylista,linegetagentactivitylistw,linegetagentcaps,'+
    'linegetagentcapsa,linegetagentcapsw,linegetagentgrouplist,'+
    'linegetagentgrouplista,linegetagentgrouplistw,linegetagentinfo,'+
    'linegetagentsessioninfo,linegetagentsessionlist,linegetagentstatus,'+
    'linegetagentstatusa,linegetagentstatusw,linegetapppriority,linegetappprioritya,'+
    'linegetapppriorityw,linegetcallinfo,linegetcallinfoa,linegetcallinfow,'+
    'linegetcallstatus,linegetconfrelatedcalls,linegetcountry,linegetcountrya,'+
    'linegetcountryw,linegetdevcaps,linegetdevcapsa,linegetdevcapsw,linegetdevconfig,'+
    'linegetdevconfiga,linegetdevconfigw,linegetgrouplist,linegetgrouplista,'+
    'linegetgrouplistw,linegeticon,linegeticona,linegeticonw,linegetid,linegetida,'+
    'linegetidw,linegetlinedevstatus,linegetlinedevstatusa,linegetlinedevstatusw,'+
    'linegetmessage,linegetnewcalls,linegetnumrings,linegetproviderlist,'+
    'linegetproviderlista,linegetproviderlistw,linegetproxystatus,linegetqueueinfo,'+
    'linegetqueuelist,linegetqueuelista,linegetqueuelistw,linegetrequest,'+
    'linegetrequesta,linegetrequestw,linegetstatusmessages,linegettranslatecaps,'+
    'linegettranslatecapsa,linegettranslatecapsw,linehandoff,linehandoffa,'+
    'linehandoffw,linehold,lineinitialize,lineinitializeex,lineinitializeexa,'+
    'lineinitializeexw,linemakecall,linemakecalla,linemakecallw,linemonitordigits,'+
    'linemonitormedia,linemonitortones,linenegotiateapiversion,'+
    'linenegotiateextversion,lineopen,lineopena,lineopenw,linepark,lineparka,'+
    'lineparkw,linepickup,linepickupa,linepickupw,lineprepareaddtoconference,'+
    'lineprepareaddtoconferencea,lineprepareaddtoconferencew,lineproxymessage,'+
    'lineproxyresponse,lineredirect,lineredirecta,lineredirectw,'+
    'lineregisterrequestrecipient,linereleaseuseruserinfo,lineremovefromconference,'+
    'lineremoveprovider,linesecurecall,linesenduseruserinfo,linesetagentactivity,'+
    'linesetagentgroup,linesetagentmeasurementperiod,linesetagentsessionstate,'+
    'linesetagentstate,linesetagentstateex,linesetapppriority,linesetappprioritya,'+
    'linesetapppriorityw,linesetappspecific,linesetcalldata,linesetcallparams,'+
    'linesetcallprivilege,linesetcallqualityofservice,linesetcalltreatment,'+
    'linesetcurrentlocation,linesetdevconfig,linesetdevconfiga,linesetdevconfigw,'+
    'linesetlinedevstatus,linesetmediacontrol,linesetmediamode,linesetnumrings,'+
    'linesetqueuemeasurementperiod,linesetstatusmessages,linesetterminal,'+
    'linesettolllist,linesettolllista,linesettolllistw,linesetupconference,'+
    'linesetupconferencea,linesetupconferencew,linesetuptransfer,linesetuptransfera,'+
    'linesetuptransferw,lineshutdown,lineswaphold,lineto,linetranslateaddress,'+
    'linetranslateaddressa,linetranslateaddressw,linetranslatedialog,'+
    'linetranslatedialoga,linetranslatedialogw,lineuncompletecall,lineunhold,'+
    'lineunpark,lineunparka,lineunparkw,link,linkb,listcalls,listen,'+
    'llscapabilityissupported,llscertificateclaimadd,llscertificateclaimadda,'+
    'llscertificateclaimaddcheck,llscertificateclaimaddchecka,'+
    'llscertificateclaimaddcheckw,llscertificateclaimaddw,llsclose,llsconnect,'+
    'llsconnecta,llsconnectenterprise,llsconnectenterprisea,llsconnectenterprisew,'+
    'llsconnectw,llsenterpriseserverfind,llsenterpriseserverfinda,'+
    'llsenterpriseserverfindw,llsfreememory,llsgroupadd,llsgroupadda,llsgroupaddw,'+
    'llsgroupdelete,llsgroupdeletea,llsgroupdeletew,llsgroupenum,llsgroupenuma,'+
    'llsgroupenumw,llsgroupinfoget,llsgroupinfogeta,llsgroupinfogetw,llsgroupinfoset,'+
    'llsgroupinfoseta,llsgroupinfosetw,llsgroupuseradd,llsgroupuseradda,'+
    'llsgroupuseraddw,llsgroupuserdelete,llsgroupuserdeletea,llsgroupuserdeletew,'+
    'llsgroupuserenum,llsgroupuserenuma,llsgroupuserenumw,llslicenseadd,'+
    'llslicenseadda,llslicenseaddw,llslicenseenum,llslicenseenuma,llslicenseenumw,'+
    'llslicensefree,llslicensefree2,llslicenserequest,llslicenserequest2,'+
    'llslicenserequest2a,llslicenserequest2w,llslicenserequesta,llslicenserequestw,'+
    'llslocalserviceenum,llslocalserviceenuma,llslocalserviceenumw,'+
    'llslocalserviceinfoget,llslocalserviceinfogeta,llslocalserviceinfogetw,'+
    'llslocalserviceinfoset,llslocalserviceinfoseta,llslocalserviceinfosetw,'+
    'llsproductadd,llsproductadda,llsproductaddw,llsproductenum,llsproductenuma,'+
    'llsproductenumw,llsproductlicenseenum,llsproductlicenseenuma,'+
    'llsproductlicenseenumw,llsproductlicensesget,llsproductlicensesgeta,'+
    'llsproductlicensesgetw,llsproductsecurityget,llsproductsecuritygeta,'+
    'llsproductsecuritygetw,llsproductsecurityset,llsproductsecurityseta,'+
    'llsproductsecuritysetw,llsproductserverenum,llsproductserverenuma,'+
    'llsproductserverenumw,llsproductuserenum,llsproductuserenuma,'+
    'llsproductuserenumw,llsreplclose,llsreplconnect,llsreplconnectw,'+
    'llsreplicationcertdbadd,llsreplicationcertdbaddw,'+
    'llsreplicationproductsecurityadd,llsreplicationproductsecurityaddw,'+
    'llsreplicationrequest,llsreplicationrequestw,llsreplicationserveradd,'+
    'llsreplicationserveraddw,llsreplicationserverserviceadd,'+
    'llsreplicationserverserviceaddw,llsreplicationserviceadd,'+
    'llsreplicationserviceaddw,llsreplicationuseradd,llsreplicationuseraddex,'+
    'llsreplicationuseraddexw,llsreplicationuseraddw,llsserviceinfoget,'+
    'llsserviceinfogeta,llsserviceinfogetw,llsserviceinfoset,llsserviceinfoseta,'+
    'llsserviceinfosetw,llsuserdelete,llsuserdeletea,llsuserdeletew,llsuserenum,'+
    'llsuserenuma,llsuserenumw,llsuserinfoget,llsuserinfogeta,llsuserinfogetw,'+
    'llsuserinfoset,llsuserinfoseta,llsuserinfosetw,llsuserproductdelete,'+
    'llsuserproductdeletea,llsuserproductdeletew,llsuserproductenum,'+
    'llsuserproductenuma,llsuserproductenumw,lm_init,lm_init_clear_tables,'+
    'lm_init_use_tables,load_drives,loadaccelerators,loadacceleratorsa,'+
    'loadacceleratorsw,loadalterbitmap,loadbhifilter,loadbinaryfilter,loadbitmap,'+
    'loadbitmapa,loadbitmapw,loadcapture,loadcapturew,loadcurrentpwrscheme,'+
    'loadcursor,loadcursora,loadcursorfromfile,loadcursorfromfilea,'+
    'loadcursorfromfilew,loadcursorw,loaddriver,loaddriverfiletoconvertdevmode,'+
    'loaddriverwithversion,loadexpertconfiguration,loadgroup,loadicon,loadicona,'+
    'loadiconw,loadifilter,loadimage,loadimagea,loadimagew,loadkeyboardlayout,'+
    'loadkeyboardlayouta,loadkeyboardlayoutw,loadlibrary,loadlibrarya,loadlibraryex,'+
    'loadlibraryexa,loadlibraryexw,loadlibraryw,loadlist,loadmenu,loadmenua,'+
    'loadmenuindirect,loadmenuindirecta,loadmenuindirectw,loadmenuw,loadmodule,'+
    'loadmoffrominstalledservice,loadmoffrominstalledservicea,'+
    'loadmoffrominstalledservicew,loadperfcountertextstrings,'+
    'loadperfcountertextstringsa,loadperfcountertextstringsw,loadprinterdriver,'+
    'loadregtypelib,loadresource,loadstring,loadstringa,loadstringw,loadtextfilter,'+
    'loadtypelib,loadtypelibex,loadurlcachecontent,loaduserprofile,loaduserprofilea,'+
    'loaduserprofilew,localalloc,localallocstring,localallocstringa,'+
    'localallocstringa2,localallocstringa2w,localallocstringlen,localallocstringlena,'+
    'localallocstringlenw,localallocstringw,localallocstringw2a,localcompact,'+
    'localenroll,localenrollnods,localfiletimetofiletime,localflags,localfree,'+
    'localfreestring,localfreestringa,localfreestringw,localhandle,locallock,'+
    'localquerystring,localquerystringa,localquerystringw,localrealloc,localshrink,'+
    'localsize,localunlock,locate,locatecatalogs,locatecatalogsa,locatecatalogsw,'+
    'lockblob,lockfile,lockfileex,lockframe,lockframepropertytable,lockframetext,'+
    'lockhandle,lockresource,lockservicedatabase,locksetforegroundwindow,'+
    'lockwindowupdate,lockworkstation,locwizarddlgproc,logerror,logerrora,logerrorw,'+
    'logevent,logeventa,logeventw,logincabinet,logoffhappened,logonhappened,'+
    'logonidfromwinstationname,logonidfromwinstationnamea,logonidfromwinstationnamew,'+
    'logonuser,logonusera,logonuserex,logonuserexa,logonuserexw,logonuserw,'+
    'logwmitraceevent,longest_match,lookupaccountname,lookupaccountnamea,'+
    'lookupaccountnamew,lookupaccountsid,lookupaccountsida,lookupaccountsidw,'+
    'lookupbytesetstring,lookupdwordsetstring,lookupiconidfromdirectory,'+
    'lookupiconidfromdirectoryex,lookupprivilegedisplayname,'+
    'lookupprivilegedisplaynamea,lookupprivilegedisplaynamew,lookupprivilegename,'+
    'lookupprivilegenamea,lookupprivilegenamew,lookupprivilegevalue,'+
    'lookupprivilegevaluea,lookupprivilegevaluew,lookuproute,lookuprouteinformation,'+
    'lookuprouteinformationwithbuffer,lookupsecuritydescriptorparts,'+
    'lookupsecuritydescriptorpartsa,lookupsecuritydescriptorpartsw,'+
    'lookupwordsetstring,lopendialasst,lpcaddr,lpcbh,lpcca,lpcccall,'+
    'lpconvdlgtemplate,lpconvlockdlg,lpconvpropsheet,lpcpacket,lpcportobjecttype,'+
    'lpcrequestport,lpcrequestwaitreplyport,lpcsa,lpcscall,lpfreedlg,'+
    'lpfreedlgtemplate,lpfreepropsheet,lpgetimecomposition,lpgetimecriticalsection,'+
    'lpgetimewndproc,lpropcompareprop,lpsafearray_marshal,lpsafearray_size,'+
    'lpsafearray_unmarshal,lpsafearray_userfree,lpsafearray_usermarshal,'+
    'lpsafearray_usersize,lpsafearray_userunmarshal,lptodp,lpvalfindprop,'+
    'lpvcreatecharobject,lpvcreateconvobject,lpvcreatelangobject,'+
    'lpvcreatepunctobject,lpvgetwordbreakproc,lresultfromobject,lsaaddaccountrights,'+
    'lsaaddprivilegestoaccount,lsaapcallpackage,lsaapcallpackagepassthrough,'+
    'lsaapcallpackageuntrusted,lsaapinitializepackage,lsaaplogonterminated,'+
    'lsaaplogonuserex2,lsacallauthenticationpackage,lsaclearauditlog,lsaclose,'+
    'lsaconnectuntrusted,lsacreateaccount,lsacreatesecret,lsacreatetrusteddomain,'+
    'lsacreatetrusteddomainex,lsadelete,lsadeletetrusteddomain,'+
    'lsaderegisterlogonprocess,lsaenumerateaccountrights,lsaenumerateaccounts,'+
    'lsaenumerateaccountswithuserright,lsaenumeratelogonsessions,'+
    'lsaenumerateprivileges,lsaenumerateprivilegesofaccount,'+
    'lsaenumeratetrusteddomains,lsaenumeratetrusteddomainsex,lsafreememory,'+
    'lsafreereturnbuffer,lsagetlogonsessiondata,lsagetquotasforaccount,'+
    'lsagetremoteusername,lsagetsystemaccessaccount,lsagetusername,lsaiallocateheap,'+
    'lsaiallocateheapzero,lsaiauditaccountlogon,lsaiauditaccountlogonex,'+
    'lsaiauditkdcevent,lsaiauditkerberoslogon,lsaiauditlogonusingexplicitcreds,'+
    'lsaiauditnotifypackageload,lsaiauditpasswordaccessevent,lsaiauditsamevent,'+
    'lsaicallpackage,lsaicallpackageex,lsaicallpackagepassthrough,'+
    'lsaicancelnotification,lsaichangesecretcipherkey,lsaiclookupnames,'+
    'lsaiclookupnameswithcreds,lsaiclookupsids,lsaiclookupsidswithcreds,'+
    'lsaicryptprotectdata,lsaicryptunprotectdata,lsaidsnotifiedobjectchange,'+
    'lsaienumeratesecrets,lsaieventnotify,lsaifiltersids,lsaiforesttrustfindmatch,'+
    'lsaifree_lsa_forest_trust_collision_information'+
    'lsaifree_lsa_forest_trust_information,lsaifree_lsai_private_data,'+
    'lsaifree_lsai_secret_enum_buffer,lsaifree_lsap_site_info,'+
    'lsaifree_lsap_sitename_info,lsaifree_lsap_subnet_info,'+
    'lsaifree_lsap_upn_suffixes,lsaifree_lsapr_account_enum_buffer,'+
    'lsaifree_lsapr_cr_cipher_value,lsaifree_lsapr_policy_domain_information,'+
    'lsaifree_lsapr_policy_information,lsaifree_lsapr_privilege_enum_buffer,'+
    'lsaifree_lsapr_privilege_set,lsaifree_lsapr_referenced_domain_list,'+
    'lsaifree_lsapr_sr_security_descriptor,lsaifree_lsapr_translated_names,'+
    'lsaifree_lsapr_translated_sids,lsaifree_lsapr_trust_information,'+
    'lsaifree_lsapr_trusted_domain_info,lsaifree_lsapr_trusted_enum_buffer,'+
    'lsaifree_lsapr_trusted_enum_buffer_ex,lsaifree_lsapr_unicode_string,'+
    'lsaifree_lsapr_unicode_string_buffer,lsaifreedomainorginfo,'+
    'lsaifreeforesttrustinfo,lsaifreeheap,lsaifreereturnbuffer,lsaigetbootoption,'+
    'lsaigetcallinfo,lsaigetforesttrustinformation,lsaigetlogonguid,'+
    'lsaigetnbanddnsdomainnames,lsaigetprivatedata,lsaigetserialnumberpolicy,'+
    'lsaigetserialnumberpolicy2,lsaigetsitename,lsaihealthcheck,'+
    'lsaiimpersonateclient,lsaiinitializewellknownsids,lsaiisclassidlsaclass,'+
    'lsaiisdspaused,lsaikerberosregistertrustnotification,lsailookupwellknownname,'+
    'lsainotifychangenotification,lsainotifynetlogonparameterschange,'+
    'lsainotifynetlogonparameterschangew,lsainotifypasswordchanged,'+
    'lsaiopenpolicytrusted,lsaiossalloc,lsaiossfree,lsaiquerydomainorginfo,'+
    'lsaiqueryforesttrustinfo,lsaiqueryinformationpolicytrusted,lsaiquerysiteinfo,'+
    'lsaiquerysubnetinfo,lsaiqueryupnsuffixes,lsairegisternotification,'+
    'lsairegisterpolicychangenotificationcallback,lsaisafemode,'+
    'lsaisamindicateddsstarted,lsaisetbootoption,lsaisetclientdnshostname,'+
    'lsaisetlogonguidinlogonsession,lsaisetprivatedata,lsaisetserialnumberpolicy,'+
    'lsaisettimessecret,lsaisetupwasrun,lsaitestcall,'+
    'lsaiunregisterallpolicychangenotificationcallback'+
    'lsaiunregisterpolicychangenotificationcallback,lsaiupdateforesttrustinformation,'+
    'lsaiwriteauditevent,lsalogonuser,lsalookupauthenticationpackage,lsalookupnames,'+
    'lsalookupnames2,lsalookupprivilegedisplayname,lsalookupprivilegename,'+
    'lsalookupprivilegevalue,lsalookupsids,lsantstatustowinerror,lsaopenaccount,'+
    'lsaopenpolicy,lsaopenpolicysce,lsaopensecret,lsaopentrusteddomain,'+
    'lsaopentrusteddomainbyname,lsapauopensam,lsapcheckbootmode,'+
    'lsapdsdebuginitialize,lsapdsinitializedsstateinfo,'+
    'lsapdsinitializepromoteinterface,lsapinitlsa,lsaquerydomaininformationpolicy,'+
    'lsaqueryforesttrustinformation,lsaqueryinformationpolicy,'+
    'lsaqueryinfotrusteddomain,lsaquerysecret,lsaquerysecurityobject,'+
    'lsaquerytrusteddomaininfo,lsaquerytrusteddomaininfobyname,'+
    'lsaraddprivilegestoaccount,lsarclose,lsarcreateaccount,lsarcreatesecret,'+
    'lsarcreatetrusteddomain,lsarcreatetrusteddomainex,lsardelete,'+
    'lsaregisterlogonprocess,lsaregisterpolicychangenotification,'+
    'lsaremoveaccountrights,lsaremoveprivilegesfromaccount,lsarenumerateaccounts,'+
    'lsarenumerateprivileges,lsarenumerateprivilegesaccount,'+
    'lsarenumeratetrusteddomains,lsarenumeratetrusteddomainsex,'+
    'lsaretrieveprivatedata,lsargetquotasforaccount,lsargetsystemaccessaccount,'+
    'lsarlookupnames,lsarlookupprivilegedisplayname,lsarlookupprivilegename,'+
    'lsarlookupprivilegevalue,lsarlookupsids,lsarlookupsids2,lsaropenaccount,'+
    'lsaropenpolicy,lsaropenpolicysce,lsaropensecret,lsaropentrusteddomain,'+
    'lsaropentrusteddomainbyname,lsarquerydomaininformationpolicy,'+
    'lsarqueryforesttrustinformation,lsarqueryinformationpolicy,'+
    'lsarqueryinfotrusteddomain,lsarquerysecret,lsarquerysecurityobject,'+
    'lsarquerytrusteddomaininfo,lsarquerytrusteddomaininfobyname,'+
    'lsarremoveprivilegesfromaccount,lsarsetdomaininformationpolicy,'+
    'lsarsetforesttrustinformation,lsarsetinformationpolicy,'+
    'lsarsetinformationtrusteddomain,lsarsetquotasforaccount,lsarsetsecret,'+
    'lsarsetsecurityobject,lsarsetsystemaccessaccount,lsarsettrusteddomaininfobyname,'+
    'lsasetdomaininformationpolicy,lsasetforesttrustinformation,'+
    'lsasetinformationpolicy,lsasetinformationtrusteddomain,lsasetquotasforaccount,'+
    'lsasetsecret,lsasetsecurityobject,lsasetsystemaccessaccount,'+
    'lsasettrusteddomaininfobyname,lsasettrusteddomaininformation,'+
    'lsastoreprivatedata,lsaunregisterpolicychangenotification,lseek,lstrcat,'+
    'lstrcata,lstrcatw,lstrcmp,lstrcmpa,lstrcmpi,lstrcmpia,lstrcmpiw,lstrcmpw,'+
    'lstrcpy,lstrcpya,lstrcpyn,lstrcpyna,lstrcpynw,lstrcpyw,lstrlen,lstrlena,'+
    'lstrlenw,ltoa,ltok,lv_item,lvbkimage,lz_bump,lz_close,lz_init,lz_nexttoken,'+
    'lzclose,lzclosefile,lzcopy,lzcreatefile,lzcreatefilew,lzdone,lzinit,lzopenfile,'+
    'lzopenfilea,lzopenfilew,lzread,lzseek,lzstart,lzx_decode,lzx_decodefree,'+
    'lzx_decodeinit,lzx_decodenewgroup,lzx_encode,lzx_encodeflush,lzx_encodefree,'+
    'lzx_encodeinit,lzx_encodenewgroup,lzx_getinputdata,mactypetoaddresstype,'+
    'make_code,make_len,make_table,make_table_8bit,make_tree,make_tree2,'+
    'makeabsolutesd,makeabsolutesd2,makedraglist,makeselfrelativesd,makesignature,'+
    'makesuredirectorypathexists,malloc,mapandload,mapdebuginformation,mapdialogrect,'+
    'mapfileandchecksuma,mapfileandchecksumw,mapgenericmask,maphinstls,maphinstls_pn,'+
    'maphinstsl,maphinstsl_pn,mapiadminprofiles,mapiallocatebuffer,mapiallocatemore,'+
    'mapideinitidle,mapifreebuffer,mapigetdefaultmalloc,mapiinitialize,mapiinitidle,'+
    'mapilogonex,mapiopenformmgr,mapiopenlocalformcontainer,mapiuninitialize,mapls,'+
    'mapnwrightstontaccess,mapresourcetopolicy,mapsecurityerror,mapsl,mapslfix,'+
    'mapspecifictogeneric,mapspnserviceclass,mapstoragescode,mapuserphysicalpages,'+
    'mapuserphysicalpagesscatter,mapviewoffile,mapviewoffileex,mapvirtualkey,'+
    'mapvirtualkeya,mapvirtualkeyex,mapvirtualkeyexa,mapvirtualkeyexw,mapvirtualkeyw,'+
    'mapwindowpoints,marshalblob,marshalldownstructure,marshalldownstructuresarray,'+
    'marshallupstructure,marshallupstructuresarray,maskblt,'+
    'matchcrossrefbynetbiosname,matchcrossrefbysid,matchdomaindnbydnsname,'+
    'matchdomaindnbynetbiosname,mbstowcs,mbtowc,mcastapicleanup,mcastapistartup,'+
    'mcastenumeratescopes,mcastgenuid,mcastreleaseaddress,mcastrenewaddress,'+
    'mcastrequestaddress,mcdaddstate,mcdaddstatestruct,mcdalloc,mcdallocbuffers,'+
    'mcdbeginstate,mcdbindcontext,mcdclear,mcdcopypixels,mcdcreatecontext,'+
    'mcdcreatetexture,mcddeletecontext,mcddeletetexture,mcddescribelayerplane,'+
    'mcddescribemcdlayerplane,mcddescribemcdpixelformat,mcddescribepixelformat,'+
    'mcddestroywindow,mcddrawpixels,mcdengescfilter,mcdenginit,mcdenginitex,'+
    'mcdengsetmemstatus,mcdenguninit,mcdflushstate,mcdfree,mcdgetbuffers,'+
    'mcdgetdriverinfo,mcdgettextureformats,mcdlock,mcdpixelmap,mcdprocessbatch,'+
    'mcdprocessbatch2,mcdquerymemstatus,mcdreadpixels,mcdreadspan,mcdsetlayerpalette,'+
    'mcdsetscissorrect,mcdsetviewport,mcdswap,mcdswapmultiple,mcdsync,mcdtexturekey,'+
    'mcdtexturestatus,mcdunlock,mcdupdatesubtexture,mcdupdatetexturepalette,'+
    'mcdupdatetexturepriority,mcdupdatetexturestate,mcdwritespan,mci32message,'+
    'mcicompressglobal,mcicreatecompressionglobal,mcidestroycompressionglobal,'+
    'mcidrivernotify,mcidriveryield,mciexecute,mcifreecommandresource,'+
    'mcigetcreatortask,mcigetdeviceid,mcigetdeviceida,mcigetdeviceidfromelementid,'+
    'mcigetdeviceidfromelementida,mcigetdeviceidfromelementidw,mcigetdeviceidw,'+
    'mcigetdriverdata,mcigeterrorstring,mcigeterrorstringa,mcigeterrorstringw,'+
    'mcigetyieldproc,mciloadcommandresource,mciresetcompressionglobal,mcisendcommand,'+
    'mcisendcommanda,mcisendcommandw,mcisendstring,mcisendstringa,mcisendstringw,'+
    'mcisetdriverdata,mcisetyieldproc,mciwndcreate,mciwndcreatea,mciwndcreatew,'+
    'mciwndregisterclass,md4final,md4init,md4update,md5final,md5init,md5update,'+
    'mdicreatedecompressionglobal,mdidecompressglobal,mdidestroydecompressionglobal,'+
    'mdiresetdecompressionglobal,memallocias,memchr,memcopy,memcpy,memfill,'+
    'memfreeias,memmove,memorysize,memreallocias,memset,menuhelp,menuitemfrompoint,'+
    'menuiteminfo,mergeblob,mergelegacypwrscheme,mesbufferhandlereset,'+
    'mesdecodebufferhandlecreate,mesdecodeincrementalhandlecreate,'+
    'mesencodedynbufferhandlecreate,mesencodefixedbufferhandlecreate,'+
    'mesencodeincrementalhandlecreate,meshandlefree,mesincrementalhandlereset,'+
    'mesinqprocencodingid,messagebeep,messagebox,messageboxa,messageboxex,'+
    'messageboxexa,messageboxexw,messageboxindirect,messageboxindirecta,'+
    'messageboxindirectw,messageboxtimeout,messageboxtimeouta,messageboxtimeoutw,'+
    'messageboxw,mfcallbackfunc,mfchangedata,mfclone,mfcopy,mfdraw,mfenumformat,'+
    'mfequal,mfgetdata,mfquerybounds,mfrelease,mfsavetostream,mgetvdmpointer,'+
    'mgmaddgroupmembershipentry,mgmdeinitialize,mgmdeletegroupmembershipentry,'+
    'mgmderegistermprotocol,mgmgetfirstmfe,mgmgetfirstmfestats,mgmgetmfe,'+
    'mgmgetmfestats,mgmgetnextmfe,mgmgetnextmfestats,mgmgetprotocoloninterface,'+
    'mgmgroupenumerationend,mgmgroupenumerationgetnext,mgmgroupenumerationstart,'+
    'mgminitialize,mgmregistermprotocol,mgmreleaseinterfaceownership,'+
    'mgmtakeinterfaceownership,mid32message,midiconnect,mididisconnect,'+
    'midiinaddbuffer,midiinclose,midiingetdevcaps,midiingetdevcapsa,'+
    'midiingetdevcapsw,midiingeterrortext,midiingeterrortexta,midiingeterrortextw,'+
    'midiingetid,midiingetnumdevs,midiinmessage,midiinopen,midiinprepareheader,'+
    'midiinreset,midiinstart,midiinstop,midiinunprepareheader,'+
    'midioutcachedrumpatches,midioutcachepatches,midioutclose,midioutgetdevcaps,'+
    'midioutgetdevcapsa,midioutgetdevcapsw,midioutgeterrortext,midioutgeterrortexta,'+
    'midioutgeterrortextw,midioutgetid,midioutgetnumdevs,midioutgetvolume,'+
    'midioutlongmsg,midioutmessage,midioutopen,midioutprepareheader,midioutreset,'+
    'midioutsetvolume,midioutshortmsg,midioutunprepareheader,midistreamclose,'+
    'midistreamopen,midistreamout,midistreampause,midistreamposition,'+
    'midistreamproperty,midistreamrestart,midistreamstop,midl_user_allocate,'+
    'midl_user_allocate1,midl_user_free,midl_user_free1,migrate10cachedpackages,'+
    'migrate10cachedpackagesa,migrate10cachedpackagesw,migratealldrivers,'+
    'migrateexceptionpackages,migratent4tont5,migrateregisteredstiappsforwiaevents,'+
    'migratesoundevents,migratewinsockconfiguration,minidump,minidumpw,minute,'+
    'mixerclose,mixergetcontroldetails,mixergetcontroldetailsa,'+
    'mixergetcontroldetailsw,mixergetdevcaps,mixergetdevcapsa,mixergetdevcapsw,'+
    'mixergetid,mixergetlinecontrols,mixergetlinecontrolsa,mixergetlinecontrolsw,'+
    'mixergetlineinfo,mixergetlineinfoa,mixergetlineinfow,mixergetnumdevs,'+
    'mixermessage,mixeropen,mixersetcontroldetails,mkdir,mkfifo,mkparsedisplayname,'+
    'mkparsedisplaynameex,mm64bitphysicaladdress,mmaddphysicalmemory,'+
    'mmaddverifierthunks,mmadjustworkingsetsize,mmadvancemdl,'+
    'mmallocatecontiguousmemory,mmallocatecontiguousmemoryspecifycache,'+
    'mmallocatemappingaddress,mmallocatenoncachedmemory,mmallocatepagesformdl,'+
    'mmallocatepagesformdlex,mmbuildmdlfornonpagedpool,mmcaddprovider,'+
    'mmcanfilebetruncated,mmcconfigprovider,mmcgetavailableproviders,'+
    'mmcgetdeviceflags,mmcgetlineinfo,mmcgetlinestatus,mmcgetphoneinfo,'+
    'mmcgetphonestatus,mmcgetproviderlist,mmcgetserverconfig,mmcinitialize,'+
    'mmcommitsessionmappedview,mmcreatemdl,mmcreatemirror,mmcreatesection,'+
    'mmcremoveprovider,mmcsetlineinfo,mmcsetphoneinfo,mmcsetserverconfig,mmcshutdown,'+
    'mmdisablemodifiedwriteofsection,mmdrvinstall,mmflushimagesection,'+
    'mmforcesectionclosed,mmfreecontiguousmemory,mmfreecontiguousmemoryspecifycache,'+
    'mmfreemappingaddress,mmfreenoncachedmemory,mmfreepagesfrommdl,mmgetcurrenttask,'+
    'mmgetphysicaladdress,mmgetphysicalmemoryranges,mmgetsystemroutineaddress,'+
    'mmgetvirtualforphysical,mmgrowkernelstack,mmhighestuseraddress,mmioadvance,'+
    'mmioascend,mmioclose,mmiocreatechunk,mmiodescend,mmioflush,mmiogetinfo,'+
    'mmioinstallioproc,mmioinstallioproca,mmioinstallioprocw,mmioopen,mmioopena,'+
    'mmioopenw,mmioread,mmiorename,mmiorenamea,mmiorenamew,mmioseek,mmiosendmessage,'+
    'mmiosetbuffer,mmiosetinfo,mmiostringtofourcc,mmiostringtofourcca,'+
    'mmiostringtofourccw,mmiowrite,mmisaddressvalid,mmisdriververifying,'+
    'mmisiospaceactive,mmisnonpagedsystemaddressvalid,mmisrecursiveiofault,'+
    'mmisthisanntassystem,mmisverifierenabled,mmlockpagabledatasection,'+
    'mmlockpagableimagesection,mmlockpagablesectionbyhandle,mmmapiospace,'+
    'mmmaplockedpages,mmmaplockedpagesspecifycache,'+
    'mmmaplockedpageswithreservedmapping,mmmapmemorydumpmdl,mmmapuseraddressestopage,'+
    'mmmapvideodisplay,mmmapviewinsessionspace,mmmapviewinsystemspace,'+
    'mmmapviewofsection,mmmarkphysicalmemoryasbad,mmmarkphysicalmemoryasgood,'+
    'mmpageentiredriver,mmprefetchpages,mmprobeandlockpages,'+
    'mmprobeandlockprocesspages,mmprobeandlockselectedpages,'+
    'mmprotectmdlsystemaddress,mmquerysystemsize,mmremovephysicalmemory,'+
    'mmresetdriverpaging,mmsectionobjecttype,mmsecurevirtualmemory,'+
    'mmsetaddressrangemodified,mmsetbankedsection,mmsizeofmdl,mmsystemgetversion,'+
    'mmsystemrangestart,mmtaskblock,mmtaskcreate,mmtasksignal,mmtaskyield,'+
    'mmtrimallsystempagablememory,mmunlockpagableimagesection,mmunlockpages,'+
    'mmunmapiospace,mmunmaplockedpages,mmunmapreservedmapping,mmunmapvideodisplay,'+
    'mmunmapviewinsessionspace,mmunmapviewinsystemspace,mmunmapviewofsection,'+
    'mmunsecurevirtualmemory,mmuserprobeaddress,mnls_comparestring,'+
    'mnls_comparestringw,mnls_isbadstringptr,mnls_isbadstringptrw,mnls_lstrcmp,'+
    'mnls_lstrcmpw,mnls_lstrcpy,mnls_lstrcpyw,mnls_lstrlen,mnls_lstrlenw,'+
    'mnls_multibytetowidechar,mnls_widechartomultibyte,mobsyncgetclassobject,'+
    'mocopymediatype,mocreatemediatype,mod32message,modeletemediatype,modifyframe,'+
    'modifymenu,modifymenua,modifymenuw,modifyworldtransform,module32first,'+
    'module32firstw,module32next,module32nextw,moduplicatemediatype,mofreemediatype,'+
    'moinitmediatype,monikercommonprefixwith,monikerrelativepathto,monitorfrompoint,'+
    'monitorfromrect,monitorfromwindow,monitorinfoex,month,monthname,mountntmsmedia,'+
    'mouse_event,mouseclassinstaller,moveclustergroup,movefile,movefilea,movefileex,'+
    'movefileexa,movefileexw,movefilew,movefilewithprogress,movefilewithprogressa,'+
    'movefilewithprogressw,movetoex,movetontmsmediapool,movewindow,mpheapalloc,'+
    'mpheapcompact,mpheapcreate,mpheapdestroy,mpheapfree,mpheaprealloc,mpheapsize,'+
    'mpheapvalidate,mpradminbufferfree,mpradminconnectionclearstats,'+
    'mpradminconnectionenum,mpradminconnectiongetinfo,'+
    'mpradminderegisterconnectionnotification,mpradmindeviceenum,'+
    'mpradminestablishdomainrasserver,mpradmingeterrorstring,mpradmingetpdcserver,'+
    'mpradmininterfaceconnect,mpradmininterfacecreate,mpradmininterfacedelete,'+
    'mpradmininterfacedevicegetinfo,mpradmininterfacedevicesetinfo,'+
    'mpradmininterfacedisconnect,mpradmininterfaceenum,'+
    'mpradmininterfacegetcredentials,mpradmininterfacegetcredentialsex,'+
    'mpradmininterfacegethandle,mpradmininterfacegetinfo,'+
    'mpradmininterfacequeryupdateresult,mpradmininterfacesetcredentials,'+
    'mpradmininterfacesetcredentialsex,mpradmininterfacesetinfo,'+
    'mpradmininterfacetransportadd,mpradmininterfacetransportgetinfo,'+
    'mpradmininterfacetransportremove,mpradmininterfacetransportsetinfo,'+
    'mpradmininterfaceupdatephonebookinfo,mpradmininterfaceupdateroutes,'+
    'mpradminisdomainrasserver,mpradminisservicerunning,mpradminmibbufferfree,'+
    'mpradminmibentrycreate,mpradminmibentrydelete,mpradminmibentryget,'+
    'mpradminmibentrygetfirst,mpradminmibentrygetnext,mpradminmibentryset,'+
    'mpradminmibserverconnect,mpradminmibserverdisconnect,mpradminportclearstats,'+
    'mpradminportdisconnect,mpradminportenum,mpradminportgetinfo,mpradminportreset,'+
    'mpradminregisterconnectionnotification,mpradminsendusermessage,'+
    'mpradminserverconnect,mpradminserverdisconnect,mpradminservergetcredentials,'+
    'mpradminservergetinfo,mpradminserversetcredentials,mpradmintransportcreate,'+
    'mpradmintransportgetinfo,mpradmintransportsetinfo,mpradminupgradeusers,'+
    'mpradminuserclose,mpradminusergetinfo,mpradminuseropen,mpradminuserread,'+
    'mpradminuserreadprofflags,mpradminuserserverconnect,'+
    'mpradminuserserverdisconnect,mpradminusersetinfo,mpradminuserwrite,'+
    'mpradminuserwriteprofflags,mprconfigbufferfree,mprconfiggetfriendlyname,'+
    'mprconfiggetguidname,mprconfiginterfacecreate,mprconfiginterfacedelete,'+
    'mprconfiginterfaceenum,mprconfiginterfacegethandle,mprconfiginterfacegetinfo,'+
    'mprconfiginterfacesetinfo,mprconfiginterfacetransportadd,'+
    'mprconfiginterfacetransportenum,mprconfiginterfacetransportgethandle,'+
    'mprconfiginterfacetransportgetinfo,mprconfiginterfacetransportremove,'+
    'mprconfiginterfacetransportsetinfo,mprconfigserverbackup,mprconfigserverconnect,'+
    'mprconfigserverdisconnect,mprconfigservergetinfo,mprconfigserverinstall,'+
    'mprconfigserverinstallprivate,mprconfigserverrefresh,mprconfigserverrestore,'+
    'mprconfigserverunattendedinstall,mprconfigtransportcreate,'+
    'mprconfigtransportdelete,mprconfigtransportenum,mprconfigtransportgethandle,'+
    'mprconfigtransportgetinfo,mprconfigtransportsetinfo,mprdomainqueryaccess,'+
    'mprdomainqueryrasserver,mprdomainregisterrasserver,mprdomainsetaccess,'+
    'mprgetusrparams,mprinfoblockadd,mprinfoblockfind,mprinfoblockquerysize,'+
    'mprinfoblockremove,mprinfoblockset,mprinfocreate,mprinfodelete,mprinfoduplicate,'+
    'mprinforemoveall,mprportsetusage,mprserviceproc,'+
    'mprsetupipinipinterfacefriendlynamecreate'+
    'mprsetupipinipinterfacefriendlynamedelete'+
    'mprsetupipinipinterfacefriendlynameenum,mprsetupipinipinterfacefriendlynamefree,'+
    'mprsetupprotocolenum,mprsetupprotocolfree,mqadspathtoformatname,'+
    'mqallocatememory,mqbegintransaction,mqclosecursor,mqclosequeue,mqcreatecursor,'+
    'mqcreatequeue,mqdeletequeue,mqfreememory,mqfreesecuritycontext,'+
    'mqgetmachineproperties,mqgetoverlappedresult,mqgetprivatecomputerinformation,'+
    'mqgetqueueproperties,mqgetqueuesecurity,mqgetsecuritycontext,'+
    'mqgetsecuritycontextex,mqhandletoformatname,mqinstancetoformatname,'+
    'mqlocatebegin,mqlocateend,mqlocatenext,mqmgmtaction,mqmgmtgetinfo,mqopenqueue,'+
    'mqpathnametoformatname,mqpurgequeue,mqreceivemessage,mqreceivemessagebylookupid,'+
    'mqregistercertificate,mqsendmessage,mqsetqueueproperties,mqsetqueuesecurity,'+
    'mscat32dllregisterserver,mscat32dllunregisterserver,mscatconstructhashtag,'+
    'mscatfreehashtag,mschapsrvchangepassword,mschapsrvchangepassword2,msgboxparams,'+
    'msgdsize,msgwaitformultipleobjects,msgwaitformultipleobjectsex,'+
    'msiadvertiseproduct,msiadvertiseproducta,msiadvertiseproductex,'+
    'msiadvertiseproductexa,msiadvertiseproductexw,msiadvertiseproductw,'+
    'msiadvertisescript,msiadvertisescripta,msiadvertisescriptw,'+
    'msiapplymultiplepatches,msiapplymultiplepatchesa,msiapplymultiplepatchesw,'+
    'msiapplypatch,msiapplypatcha,msiapplypatchw,msicloseallhandles,msiclosehandle,'+
    'msicollectuserinfo,msicollectuserinfoa,msicollectuserinfow,msiconfigurefeature,'+
    'msiconfigurefeaturea,msiconfigurefeaturefromdescriptor,'+
    'msiconfigurefeaturefromdescriptora,msiconfigurefeaturefromdescriptorw,'+
    'msiconfigurefeaturew,msiconfigureproduct,msiconfigureproducta,'+
    'msiconfigureproductex,msiconfigureproductexa,msiconfigureproductexw,'+
    'msiconfigureproductw,msicreateandverifyinstallerdirectory,msicreaterecord,'+
    'msicreatetransformsummaryinfo,msicreatetransformsummaryinfoa,'+
    'msicreatetransformsummaryinfow,msidatabaseapplytransform,'+
    'msidatabaseapplytransforma,msidatabaseapplytransformw,msidatabasecommit,'+
    'msidatabaseexport,msidatabaseexporta,msidatabaseexportw,'+
    'msidatabasegeneratetransform,msidatabasegeneratetransforma,'+
    'msidatabasegeneratetransformw,msidatabasegetprimarykeys,'+
    'msidatabasegetprimarykeysa,msidatabasegetprimarykeysw,msidatabaseimport,'+
    'msidatabaseimporta,msidatabaseimportw,msidatabaseistablepersistent,'+
    'msidatabaseistablepersistenta,msidatabaseistablepersistentw,msidatabasemerge,'+
    'msidatabasemergea,msidatabasemergew,msidatabaseopenview,msidatabaseopenviewa,'+
    'msidatabaseopenvieww,msidecomposedescriptor,msidecomposedescriptora,'+
    'msidecomposedescriptorw,msideleteuserdata,msideleteuserdataa,msideleteuserdataw,'+
    'msidetermineapplicablepatches,msidetermineapplicablepatchesa,'+
    'msidetermineapplicablepatchesw,msideterminepatchsequence,'+
    'msideterminepatchsequencea,msideterminepatchsequencew,msidoaction,msidoactiona,'+
    'msidoactionw,msienablelog,msienableloga,msienablelogw,msienableuipreview,'+
    'msienumclients,msienumclientsa,msienumclientsw,msienumcomponentcosts,'+
    'msienumcomponentcostsa,msienumcomponentcostsw,msienumcomponentqualifiers,'+
    'msienumcomponentqualifiersa,msienumcomponentqualifiersw,msienumcomponents,'+
    'msienumcomponentsa,msienumcomponentsw,msienumfeatures,msienumfeaturesa,'+
    'msienumfeaturesw,msienumpatches,msienumpatchesa,msienumpatchesex,'+
    'msienumpatchesexa,msienumpatchesexw,msienumpatchesw,msienumproducts,'+
    'msienumproductsa,msienumproductsex,msienumproductsexa,msienumproductsexw,'+
    'msienumproductsw,msienumrelatedproducts,msienumrelatedproductsa,'+
    'msienumrelatedproductsw,msievaluatecondition,msievaluateconditiona,'+
    'msievaluateconditionw,msiextractpatchxmldata,msiextractpatchxmldataa,'+
    'msiextractpatchxmldataw,msiformatrecord,msiformatrecorda,msiformatrecordw,'+
    'msigetactivedatabase,msigetcomponentpath,msigetcomponentpatha,'+
    'msigetcomponentpathw,msigetcomponentstate,msigetcomponentstatea,'+
    'msigetcomponentstatew,msigetdatabasestate,msigetfeaturecost,msigetfeaturecosta,'+
    'msigetfeaturecostw,msigetfeatureinfo,msigetfeatureinfoa,msigetfeatureinfow,'+
    'msigetfeaturestate,msigetfeaturestatea,msigetfeaturestatew,msigetfeatureusage,'+
    'msigetfeatureusagea,msigetfeatureusagew,msigetfeaturevalidstates,'+
    'msigetfeaturevalidstatesa,msigetfeaturevalidstatesw,msigetfilehash,'+
    'msigetfilehasha,msigetfilehashw,msigetfilesignatureinformation,'+
    'msigetfilesignatureinformationa,msigetfilesignatureinformationw,'+
    'msigetfileversion,msigetfileversiona,msigetfileversionw,msigetlanguage,'+
    'msigetlasterrorrecord,msigetmode,msigetpatchinfo,msigetpatchinfoa,'+
    'msigetpatchinfoex,msigetpatchinfoexa,msigetpatchinfoexw,msigetpatchinfow,'+
    'msigetproductcode,msigetproductcodea,msigetproductcodefrompackagecode,'+
    'msigetproductcodefrompackagecodea,msigetproductcodefrompackagecodew,'+
    'msigetproductcodew,msigetproductinfo,msigetproductinfoa,msigetproductinfoex,'+
    'msigetproductinfoexa,msigetproductinfoexw,msigetproductinfofromscript,'+
    'msigetproductinfofromscripta,msigetproductinfofromscriptw,msigetproductinfow,'+
    'msigetproductproperty,msigetproductpropertya,msigetproductpropertyw,'+
    'msigetproperty,msigetpropertya,msigetpropertyw,msigetshortcuttarget,'+
    'msigetshortcuttargeta,msigetshortcuttargetw,msigetsourcepath,msigetsourcepatha,'+
    'msigetsourcepathw,msigetsummaryinformation,msigetsummaryinformationa,'+
    'msigetsummaryinformationw,msigettargetpath,msigettargetpatha,msigettargetpathw,'+
    'msigetuserinfo,msigetuserinfoa,msigetuserinfow,msiinstallmissingcomponent,'+
    'msiinstallmissingcomponenta,msiinstallmissingcomponentw,msiinstallmissingfile,'+
    'msiinstallmissingfilea,msiinstallmissingfilew,msiinstallproduct,'+
    'msiinstallproducta,msiinstallproductw,msiinvalidatefeaturecache,'+
    'msiisproductelevated,msiisproductelevateda,msiisproductelevatedw,msiloadstring,'+
    'msiloadstringa,msiloadstringw,msilocatecomponent,msilocatecomponenta,'+
    'msilocatecomponentw,msimessagebox,msimessageboxa,msimessageboxex,'+
    'msimessageboxexa,msimessageboxexw,msimessageboxw,msinotifysidchange,'+
    'msinotifysidchangea,msinotifysidchangew,msiopendatabase,msiopendatabasea,'+
    'msiopendatabasew,msiopenpackage,msiopenpackagea,msiopenpackageex,'+
    'msiopenpackageexa,msiopenpackageexw,msiopenpackagew,msiopenproduct,'+
    'msiopenproducta,msiopenproductw,msipreviewbillboard,msipreviewbillboarda,'+
    'msipreviewbillboardw,msipreviewdialog,msipreviewdialoga,msipreviewdialogw,'+
    'msiprocessadvertisescript,msiprocessadvertisescripta,msiprocessadvertisescriptw,'+
    'msiprocessmessage,msiprovideassembly,msiprovideassemblya,msiprovideassemblyw,'+
    'msiprovidecomponent,msiprovidecomponenta,msiprovidecomponentfromdescriptor,'+
    'msiprovidecomponentfromdescriptora,msiprovidecomponentfromdescriptorw,'+
    'msiprovidecomponentw,msiprovidequalifiedcomponent,msiprovidequalifiedcomponenta,'+
    'msiprovidequalifiedcomponentex,msiprovidequalifiedcomponentexa,'+
    'msiprovidequalifiedcomponentexw,msiprovidequalifiedcomponentw,'+
    'msiquerycomponentstate,msiquerycomponentstatea,msiquerycomponentstatew,'+
    'msiqueryfeaturestate,msiqueryfeaturestatea,msiqueryfeaturestateex,'+
    'msiqueryfeaturestateexa,msiqueryfeaturestateexw,'+
    'msiqueryfeaturestatefromdescriptor,msiqueryfeaturestatefromdescriptora,'+
    'msiqueryfeaturestatefromdescriptorw,msiqueryfeaturestatew,msiqueryproductstate,'+
    'msiqueryproductstatea,msiqueryproductstatew,msirecordcleardata,'+
    'msirecorddatasize,msirecordgetfieldcount,msirecordgetinteger,msirecordgetstring,'+
    'msirecordgetstringa,msirecordgetstringw,msirecordisnull,msirecordreadstream,'+
    'msirecordsetinteger,msirecordsetstream,msirecordsetstreama,msirecordsetstreamw,'+
    'msirecordsetstring,msirecordsetstringa,msirecordsetstringw,msireinstallfeature,'+
    'msireinstallfeaturea,msireinstallfeaturefromdescriptor,'+
    'msireinstallfeaturefromdescriptora,msireinstallfeaturefromdescriptorw,'+
    'msireinstallfeaturew,msireinstallproduct,msireinstallproducta,'+
    'msireinstallproductw,msiremovepatches,msiremovepatchesa,msiremovepatchesw,'+
    'msisequence,msisequencea,msisequencew,msisetcomponentstate,'+
    'msisetcomponentstatea,msisetcomponentstatew,msisetexternalui,msisetexternaluia,'+
    'msisetexternaluiw,msisetfeatureattributes,msisetfeatureattributesa,'+
    'msisetfeatureattributesw,msisetfeaturestate,msisetfeaturestatea,'+
    'msisetfeaturestatew,msisetinstalllevel,msisetinternalui,msisetmode,'+
    'msisetproperty,msisetpropertya,msisetpropertyw,msisettargetpath,'+
    'msisettargetpatha,msisettargetpathw,msisourcelistaddmediadisk,'+
    'msisourcelistaddmediadiska,msisourcelistaddmediadiskw,msisourcelistaddsource,'+
    'msisourcelistaddsourcea,msisourcelistaddsourceex,msisourcelistaddsourceexa,'+
    'msisourcelistaddsourceexw,msisourcelistaddsourcew,msisourcelistclearall,'+
    'msisourcelistclearalla,msisourcelistclearallex,msisourcelistclearallexa,'+
    'msisourcelistclearallexw,msisourcelistclearallw,msisourcelistclearmediadisk,'+
    'msisourcelistclearmediadiska,msisourcelistclearmediadiskw,'+
    'msisourcelistclearsource,msisourcelistclearsourcea,msisourcelistclearsourcew,'+
    'msisourcelistenummediadisks,msisourcelistenummediadisksa,'+
    'msisourcelistenummediadisksw,msisourcelistenumsources,msisourcelistenumsourcesa,'+
    'msisourcelistenumsourcesw,msisourcelistforceresolution,'+
    'msisourcelistforceresolutiona,msisourcelistforceresolutionex,'+
    'msisourcelistforceresolutionexa,msisourcelistforceresolutionexw,'+
    'msisourcelistforceresolutionw,msisourcelistgetinfo,msisourcelistgetinfoa,'+
    'msisourcelistgetinfow,msisourcelistsetinfo,msisourcelistsetinfoa,'+
    'msisourcelistsetinfow,msisummaryinfogetproperty,msisummaryinfogetpropertya,'+
    'msisummaryinfogetpropertycount,msisummaryinfogetpropertyw,msisummaryinfopersist,'+
    'msisummaryinfosetproperty,msisummaryinfosetpropertya,msisummaryinfosetpropertyw,'+
    'msiusefeature,msiusefeaturea,msiusefeatureex,msiusefeatureexa,msiusefeatureexw,'+
    'msiusefeaturew,msiverifydiskspace,msiverifypackage,msiverifypackagea,'+
    'msiverifypackagew,msiviewclose,msiviewexecute,msiviewfetch,msiviewgetcolumninfo,'+
    'msiviewgeterror,msiviewgeterrora,msiviewgeterrorw,msiviewmodify,'+
    'mssip32dllregisterserver,mssip32dllunregisterserver,'+
    'msv1_0exportsubauthenticationroutine,msv1_0subauthenticationpresent,'+
    'msvgetlogonattemptcount,msvsamlogoff,msvsamvalidate,msvvalidatetarget,'+
    'mtscreateactivity,mtxaddrfromtransportaddr,mtxsame,muldiv,multibytetowidechar,'+
    'multinetgetconnectionperformance,multinetgetconnectionperformancea,'+
    'multinetgetconnectionperformancew,mxd32message,namefrompath,namefrompathw,'+
    'namematched,namematchedstringnameonly,nameprefix,ncheckimemessage,'+
    'nddegeterrorstring,nddegeterrorstringa,nddegeterrorstringw,nddegetsharesecurity,'+
    'nddegetsharesecuritya,nddegetsharesecurityw,nddegettrustedshare,'+
    'nddegettrustedsharea,nddegettrustedsharew,nddeisvalidapptopiclist,'+
    'nddeisvalidapptopiclista,nddeisvalidapptopiclistw,nddeisvalidsharename,'+
    'nddeisvalidsharenamea,nddeisvalidsharenamew,nddesetsharesecurity,'+
    'nddesetsharesecuritya,nddesetsharesecurityw,nddesettrustedshare,'+
    'nddesettrustedsharea,nddesettrustedsharew,nddeshareadd,nddeshareadda,'+
    'nddeshareaddw,nddesharedel,nddesharedela,nddesharedelw,nddeshareenum,'+
    'nddeshareenuma,nddeshareenumw,nddesharegetinfo,nddesharegetinfoa,'+
    'nddesharegetinfow,nddesharesetinfo,nddesharesetinfoa,nddesharesetinfow,'+
    'nddespecialcommand,nddespecialcommanda,nddespecialcommandw,nddetrustedshareenum,'+
    'nddetrustedshareenuma,nddetrustedshareenumw,ndetectcodefromesc,'+
    'ndetectcodefromsz,ndis_buffer_to_span_pages,ndisacquirereadwritelock,'+
    'ndisacquirespinlock,ndisadjustbufferlength,ndisallocatebuffer,'+
    'ndisallocatebufferpool,ndisallocatefromblockpool,ndisallocatememory,'+
    'ndisallocatememorywithtag,ndisallocatepacket,ndisallocatepacketpool,'+
    'ndisallocatepacketpoolex,ndisallocatespinlock,ndisansistringtounicodestring,'+
    'ndisbufferlength,ndisbuffervirtualaddress,ndiscancelsendpackets,ndiscanceltimer,'+
    'ndiscladdparty,ndisclcloseaddressfamily,ndisclclosecall,ndisclderegistersap,'+
    'ndiscldropparty,ndisclgetprotocolvccontextfromtapicallid,'+
    'ndisclincomingcallcomplete,ndisclmakecall,ndisclmodifycallqos,'+
    'ndisclopenaddressfamily,ndiscloseadapter,ndiscloseconfiguration,ndisclosefile,'+
    'ndisclregistersap,ndiscmactivatevc,ndiscmaddpartycomplete,'+
    'ndiscmcloseaddressfamilycomplete,ndiscmclosecallcomplete,ndiscmdeactivatevc,'+
    'ndiscmderegistersapcomplete,ndiscmdispatchcallconnected,'+
    'ndiscmdispatchincomingcall,ndiscmdispatchincomingcallqoschange,'+
    'ndiscmdispatchincomingclosecall,ndiscmdispatchincomingdropparty,'+
    'ndiscmdroppartycomplete,ndiscmmakecallcomplete,ndiscmmodifycallqoscomplete,'+
    'ndiscmopenaddressfamilycomplete,ndiscmregisteraddressfamily,'+
    'ndiscmregistersapcomplete,ndiscoassigninstancename,ndiscocreatevc,'+
    'ndiscodeletevc,ndiscogettapicallid,ndiscompareansistring,'+
    'ndiscompareunicodestring,ndiscompletebindadapter,ndiscompletedmatransfer,'+
    'ndiscompletepnpevent,ndiscompleteunbindadapter,ndisconvertstringtoatmaddress,'+
    'ndiscopybuffer,ndiscopyfrompackettopacket,ndiscopyfrompackettopacketsafe,'+
    'ndiscorequest,ndiscorequestcomplete,ndiscosendpackets,ndiscreateblockpool,'+
    'ndisderegisterprotocol,ndisderegistertdicallback,ndisdestroyblockpool,'+
    'ndisdpracquirespinlock,ndisdprallocatepacket,'+
    'ndisdprallocatepacketnoninterlocked,ndisdprfreepacket,'+
    'ndisdprfreepacketnoninterlocked,ndisdprreleasespinlock,ndisequalstring,'+
    'ndisfreebuffer,ndisfreebufferpool,ndisfreememory,ndisfreepacket,'+
    'ndisfreepacketpool,ndisfreespinlock,ndisfreetoblockpool,'+
    'ndisgeneratepartialcancelid,ndisgetbufferphysicalarraysize,'+
    'ndisgetcurrentprocessorcounts,ndisgetcurrentprocessorcpuusage,'+
    'ndisgetcurrentsystemtime,ndisgetdriverhandle,ndisgetfirstbufferfrompacket,'+
    'ndisgetfirstbufferfrompacketsafe,ndisgetpacketcancelid,ndisgetpoolfrompacket,'+
    'ndisgetreceivedpacket,ndisgetroutineaddress,ndisgetshareddataalignment,'+
    'ndisgetsystemuptime,ndisgetversion,ndisimassociateminiport,'+
    'ndisimcancelinitializedeviceinstance,ndisimcopysendcompleteperpacketinfo,'+
    'ndisimcopysendperpacketinfo,ndisimdeinitializedeviceinstance,'+
    'ndisimderegisterlayeredminiport,ndisimgetbindingcontext,'+
    'ndisimgetcurrentpacketstack,ndisimgetdevicecontext,'+
    'ndisiminitializedeviceinstance,ndisiminitializedeviceinstanceex,'+
    'ndisimmediatereadpcislotinformation,ndisimmediatereadportuchar,'+
    'ndisimmediatereadportulong,ndisimmediatereadportushort,'+
    'ndisimmediatereadsharedmemory,ndisimmediatewritepcislotinformation,'+
    'ndisimmediatewriteportuchar,ndisimmediatewriteportulong,'+
    'ndisimmediatewriteportushort,ndisimmediatewritesharedmemory,'+
    'ndisimnotifypnpevent,ndisimqueueminiportcallback,ndisimregisterlayeredminiport,'+
    'ndisimrevertback,ndisimswitchtominiport,ndisinitansistring,ndisinitializeevent,'+
    'ndisinitializereadwritelock,ndisinitializestring,ndisinitializetimer,'+
    'ndisinitializewrapper,ndisinitunicodestring,ndisinterlockedaddlargeinterger,'+
    'ndisinterlockedaddulong,ndisinterlockeddecrement,ndisinterlockedincrement,'+
    'ndisinterlockedinsertheadlist,ndisinterlockedinserttaillist,'+
    'ndisinterlockedpopentrylist,ndisinterlockedpushentrylist,'+
    'ndisinterlockedremoveheadlist,ndismallocatemapregisters,'+
    'ndismallocatesharedmemory,ndismallocatesharedmemoryasync,ndismapfile,'+
    'ndismatchpdowithpacket,ndismcanceltimer,ndismcloselog,ndismcmactivatevc,'+
    'ndismcmcreatevc,ndismcmdeactivatevc,ndismcmdeletevc,'+
    'ndismcmregisteraddressfamily,ndismcmrequest,ndismcoactivatevccomplete,'+
    'ndismcodeactivatevccomplete,ndismcoindicatereceivepacket,ndismcoindicatestatus,'+
    'ndismcompletebufferphysicalmapping,ndismcoreceivecomplete,'+
    'ndismcorequestcomplete,ndismcosendcomplete,ndismcreatelog,'+
    'ndismderegisteradaptershutdownhandler,ndismderegisterdevice,'+
    'ndismderegisterdmachannel,ndismderegisterinterrupt,ndismderegisterioportrange,'+
    'ndismflushlog,ndismfreemapregisters,ndismfreesharedmemory,'+
    'ndismgetdeviceproperty,ndismgetdmaalignment,ndismindicatestatus,'+
    'ndismindicatestatuscomplete,ndisminitializescattergatherdma,'+
    'ndisminitializetimer,ndismmapiospace,ndismpciassignresources,'+
    'ndismpromoteminiport,ndismqueryadapterinstancename,ndismqueryadapterresources,'+
    'ndismqueryinformationcomplete,ndismreaddmacounter,'+
    'ndismregisteradaptershutdownhandler,ndismregisterdevice,ndismregisterdmachannel,'+
    'ndismregisterinterrupt,ndismregisterioportrange,ndismregisterminiport,'+
    'ndismregisterunloadhandler,ndismremoveminiport,ndismresetcomplete,'+
    'ndismsendcomplete,ndismsendresourcesavailable,ndismsetattributes,'+
    'ndismsetattributesex,ndismsetinformationcomplete,ndismsetminiportsecondary,'+
    'ndismsetperiodictimer,ndismsettimer,ndismsleep,ndismstartbufferphysicalmapping,'+
    'ndismsynchronizewithinterrupt,ndismtransferdatacomplete,ndismunmapiospace,'+
    'ndismwanindicatereceive,ndismwanindicatereceivecomplete,ndismwansendcomplete,'+
    'ndismwritelogdata,ndisopenadapter,ndisopenconfiguration,'+
    'ndisopenconfigurationkeybyindex,ndisopenconfigurationkeybyname,ndisopenfile,'+
    'ndisopenprotocolconfiguration,ndisoverridebusnumber,ndispacketpoolusage,'+
    'ndispacketsize,ndisqueryadapterinstancename,ndisquerybindinstancename,'+
    'ndisquerybuffer,ndisquerybufferoffset,ndisquerybuffersafe,'+
    'ndisquerymapregistercount,ndisquerypendingiocount,ndisreadconfiguration,'+
    'ndisreadeisaslotinformation,ndisreadeisaslotinformationex,'+
    'ndisreadmcaposinformation,ndisreadnetworkaddress,ndisreadpcislotinformation,'+
    'ndisreadpcmciaattributememory,ndisreenumerateprotocolbindings,'+
    'ndisregisterprotocol,ndisregistertdicallback,ndisreleasereadwritelock,'+
    'ndisreleasespinlock,ndisrequest,ndisreset,ndisresetevent,ndisreturnpackets,'+
    'ndisscheduleworkitem,ndissend,ndissendpackets,ndissetevent,'+
    'ndissetpacketcancelid,ndissetpacketpoolprotocolid,ndissetpacketstatus,'+
    'ndissetprotocolfilter,ndissettimer,ndissettimerex,ndissetupdmatransfer,'+
    'ndissystemprocessorcount,ndisterminatewrapper,ndistransferdata,'+
    'ndisunchainbufferatback,ndisunchainbufferatfront,ndisunicodestringtoansistring,'+
    'ndisunmapfile,ndisupcaseunicodestring,ndisupdatesharedmemory,ndiswaitevent,'+
    'ndiswriteconfiguration,ndiswriteerrorlogentry,ndiswriteeventlogentry,'+
    'ndiswritepcislotinformation,ndiswritepcmciaattributememory,ndrallocate,'+
    'ndrasyncclientcall,ndrasyncservercall,ndrbytecountpointerbuffersize,'+
    'ndrbytecountpointerfree,ndrbytecountpointermarshall,'+
    'ndrbytecountpointerunmarshall,ndrccontextbinding,ndrccontextmarshall,'+
    'ndrccontextunmarshall,ndrclearoutparameters,ndrclientcall,ndrclientcall2,'+
    'ndrclientcontextmarshall,ndrclientcontextunmarshall,ndrclientinitialize,'+
    'ndrclientinitializenew,ndrcomplexarraybuffersize,ndrcomplexarrayfree,'+
    'ndrcomplexarraymarshall,ndrcomplexarraymemorysize,ndrcomplexarrayunmarshall,'+
    'ndrcomplexstructbuffersize,ndrcomplexstructfree,ndrcomplexstructmarshall,'+
    'ndrcomplexstructmemorysize,ndrcomplexstructunmarshall,'+
    'ndrconformantarraybuffersize,ndrconformantarrayfree,ndrconformantarraymarshall,'+
    'ndrconformantarraymemorysize,ndrconformantarrayunmarshall,'+
    'ndrconformantstringbuffersize,ndrconformantstringmarshall,'+
    'ndrconformantstringmemorysize,ndrconformantstringunmarshall,'+
    'ndrconformantstructbuffersize,ndrconformantstructfree,'+
    'ndrconformantstructmarshall,ndrconformantstructmemorysize,'+
    'ndrconformantstructunmarshall,ndrconformantvaryingarraybuffersize,'+
    'ndrconformantvaryingarrayfree,ndrconformantvaryingarraymarshall,'+
    'ndrconformantvaryingarraymemorysize,ndrconformantvaryingarrayunmarshall,'+
    'ndrconformantvaryingstructbuffersize,ndrconformantvaryingstructfree,'+
    'ndrconformantvaryingstructmarshall,ndrconformantvaryingstructmemorysize,'+
    'ndrconformantvaryingstructunmarshall,ndrcontexthandleinitialize,'+
    'ndrcontexthandlesize,ndrconvert,ndrconvert2,ndrcorrelationfree,'+
    'ndrcorrelationinitialize,ndrcorrelationpass,ndrcreateserverinterfacefromstub,'+
    'ndrcstdstubbuffer_release,ndrcstdstubbuffer2_release,ndrdcomasyncclientcall,'+
    'ndrdcomasyncstubcall,ndrdllcanunloadnow,ndrdllgetclassobject,'+
    'ndrdllregisterproxy,ndrdllunregisterproxy,ndrencapsulatedunionbuffersize,'+
    'ndrencapsulatedunionfree,ndrencapsulatedunionmarshall,'+
    'ndrencapsulatedunionmemorysize,ndrencapsulatedunionunmarshall,'+
    'ndrfixedarraybuffersize,ndrfixedarrayfree,ndrfixedarraymarshall,'+
    'ndrfixedarraymemorysize,ndrfixedarrayunmarshall,ndrfreebuffer,'+
    'ndrfullpointerfree,ndrfullpointerinsertrefid,ndrfullpointerquerypointer,'+
    'ndrfullpointerqueryrefid,ndrfullpointerxlatfree,ndrfullpointerxlatinit,'+
    'ndrgetbuffer,ndrgetdcomprotocolversion,ndrgetsimpletypebufferalignment,'+
    'ndrgetsimpletypebuffersize,ndrgetsimpletypememorysize,ndrgettypeflags,'+
    'ndrgetusermarshalinfo,ndrinterfacepointerbuffersize,ndrinterfacepointerfree,'+
    'ndrinterfacepointermarshall,ndrinterfacepointermemorysize,'+
    'ndrinterfacepointerunmarshall,ndrmapcommandfaultstatus,ndrmesprocencodedecode,'+
    'ndrmesprocencodedecode2,ndrmessimpletypealignsize,ndrmessimpletypedecode,'+
    'ndrmessimpletypeencode,ndrmestypealignsize,ndrmestypealignsize2,'+
    'ndrmestypedecode,ndrmestypedecode2,ndrmestypeencode,ndrmestypeencode2,'+
    'ndrmestypefree2,ndrnonconformantstringbuffersize,ndrnonconformantstringmarshall,'+
    'ndrnonconformantstringmemorysize,ndrnonconformantstringunmarshall,'+
    'ndrnonencapsulatedunionbuffersize,ndrnonencapsulatedunionfree,'+
    'ndrnonencapsulatedunionmarshall,ndrnonencapsulatedunionmemorysize,'+
    'ndrnonencapsulatedunionunmarshall,ndrnsgetbuffer,ndrnssendreceive,'+
    'ndroleallocate,ndrolefree,ndroutinit,ndrpartialignoreclientbuffersize,'+
    'ndrpartialignoreclientmarshall,ndrpartialignoreserverinitialize,'+
    'ndrpartialignoreserverunmarshall,ndrpcreateproxy,ndrpcreatestub,'+
    'ndrpgetprocformatstring,ndrpgettypeformatstring,ndrpgettypegencookie,'+
    'ndrpmemoryincrement,ndrpointerbuffersize,ndrpointerfree,ndrpointermarshall,'+
    'ndrpointermemorysize,ndrpointerunmarshall,ndrpreleasetypeformatstring,'+
    'ndrpreleasetypegencookie,ndrproxyerrorhandler,ndrproxyfreebuffer,'+
    'ndrproxygetbuffer,ndrproxyinitialize,ndrproxysendreceive,ndrpsetrpcssdefaults,'+
    'ndrpvarvtoftypedesc,ndrrangeunmarshall,ndrrpcsmclientallocate,'+
    'ndrrpcsmclientfree,ndrrpcsmsetclienttoosf,ndrrpcssdefaultallocate,'+
    'ndrrpcssdefaultfree,ndrrpcssdisableallocate,ndrrpcssenableallocate,'+
    'ndrscontextmarshall,ndrscontextmarshall2,ndrscontextmarshallex,'+
    'ndrscontextunmarshall,ndrscontextunmarshall2,ndrscontextunmarshallex,'+
    'ndrsendreceive,ndrservercall,ndrservercall2,ndrservercontextmarshall,'+
    'ndrservercontextnewmarshall,ndrservercontextnewunmarshall,'+
    'ndrservercontextunmarshall,ndrserverinitialize,ndrserverinitializemarshall,'+
    'ndrserverinitializenew,ndrserverinitializepartial,ndrserverinitializeunmarshall,'+
    'ndrservermarshall,ndrserverunmarshall,ndrsimplestructbuffersize,'+
    'ndrsimplestructfree,ndrsimplestructmarshall,ndrsimplestructmemorysize,'+
    'ndrsimplestructunmarshall,ndrsimpletypemarshall,ndrsimpletypeunmarshall,'+
    'ndrstubcall,ndrstubcall2,ndrstubforwardingfunction,ndrstubgetbuffer,'+
    'ndrstubinitialize,ndrstubinitializemarshall,ndrtypeflags,ndrtypefree,'+
    'ndrtypemarshall,ndrtypesize,ndrtypeunmarshall,ndrunmarshallbasetypeinline,'+
    'ndrusermarshalbuffersize,ndrusermarshalfree,ndrusermarshalmarshall,'+
    'ndrusermarshalmemorysize,ndrusermarshalsimpletypeconvert,'+
    'ndrusermarshalunmarshall,ndrvaryingarraybuffersize,ndrvaryingarrayfree,'+
    'ndrvaryingarraymarshall,ndrvaryingarraymemorysize,ndrvaryingarrayunmarshall,'+
    'ndrxmitorrepasbuffersize,ndrxmitorrepasfree,ndrxmitorrepasmarshall,'+
    'ndrxmitorrepasmemorysize,ndrxmitorrepasunmarshall,needreboot,needrebootinit,'+
    'negatepattern,netaddalternatecomputername,netalertraise,netalertraiseex,'+
    'netapibufferallocate,netapibufferfree,netapibufferreallocate,netapibuffersize,'+
    'netauditclear,netauditread,netauditwrite,netbios,netconfigget,netconfiggetall,'+
    'netconfigset,netconnectionenum,netdfsadd,netdfsaddftroot,netdfsaddstdroot,'+
    'netdfsaddstdrootforced,netdfsenum,netdfsgetclientinfo,netdfsgetdcaddress,'+
    'netdfsgetinfo,netdfsmanagerinitialize,netdfsmanagersendsiteinfo,netdfsremove,'+
    'netdfsremoveftroot,netdfsremoveftrootforced,netdfsremovestdroot,'+
    'netdfssetclientinfo,netdfssetinfo,netenumeratecomputernames,neterrorlogclear,'+
    'neterrorlogread,neterrorlogwrite,netfileclose,netfileenum,netfilegetinfo,'+
    'netgetanydcname,netgetdcname,netgetdisplayinformationindex,netgetjoinableous,'+
    'netgetjoininformation,netgroupadd,netgroupadduser,netgroupdel,netgroupdeluser,'+
    'netgroupenum,netgroupgetinfo,netgroupgetusers,netgroupsetinfo,netgroupsetusers,'+
    'netinfo_build,netinfo_clean,netinfo_copy,netinfo_free,netinfo_isforupdate,'+
    'netinfo_resetserverpriorities,netjoindomain,netlocalgroupadd,'+
    'netlocalgroupaddmember,netlocalgroupaddmembers,netlocalgroupdel,'+
    'netlocalgroupdelmember,netlocalgroupdelmembers,netlocalgroupenum,'+
    'netlocalgroupgetinfo,netlocalgroupgetmembers,netlocalgroupsetinfo,'+
    'netlocalgroupsetmembers,netlogongettimeserviceparentdomain,netmessagebuffersend,'+
    'netmessagenameadd,netmessagenamedel,netmessagenameenum,netmessagenamegetinfo,'+
    'netpdbgprint,netpntstatustoapistatus,netpparmsqueryuserproperty,'+
    'netpparmsqueryuserpropertywithlength,netpparmssetuserproperty,'+
    'netpparmssetuserpropertywithlength,netpparmsuserpropertyfree,'+
    'netpupgradeprent5joininfo,netquerydisplayinformation,'+
    'netregisterdomainnamechangenotification,netremotecomputersupports,netremotetod,'+
    'netremovealternatecomputername,netrenamemachineindomain,netreplexportdiradd,'+
    'netreplexportdirdel,netreplexportdirenum,netreplexportdirgetinfo,'+
    'netreplexportdirlock,netreplexportdirsetinfo,netreplexportdirunlock,'+
    'netreplgetinfo,netreplimportdiradd,netreplimportdirdel,netreplimportdirenum,'+
    'netreplimportdirgetinfo,netreplimportdirlock,netreplimportdirunlock,'+
    'netreplsetinfo,netrjobadd,netrjobdel,netrjobenum,netrjobgetinfo,'+
    'netschedulejobadd,netschedulejobdel,netschedulejobenum,netschedulejobgetinfo,'+
    'netservercomputernameadd,netservercomputernamedel,netserverdiskenum,'+
    'netserverenum,netservergetinfo,netserversetinfo,netservertransportadd,'+
    'netservertransportaddex,netservertransportdel,netservertransportenum,'+
    'netservicecontrol,netserviceenum,netservicegetinfo,netserviceinstall,'+
    'netsessiondel,netsessionenum,netsessiongetinfo,netsetprimarycomputername,'+
    'netshareadd,netsharecheck,netsharedel,netsharedelsticky,netshareenum,'+
    'netshareenumsticky,netsharegetinfo,netsharesetinfo,netstatisticsget,'+
    'netunjoindomain,netunregisterdomainnamechangenotification,netuseadd,netusedel,'+
    'netuseenum,netusegetinfo,netuseradd,netuserchangepassword,netuserdel,'+
    'netuserenum,netusergetgroups,netusergetinfo,netusergetlocalgroups,'+
    'netusermodalsget,netusermodalsset,netusersetgroups,netusersetinfo,'+
    'netvalidatename,netwkstagetinfo,netwkstasetinfo,netwkstatransportadd,'+
    'netwkstatransportdel,netwkstatransportenum,netwkstauserenum,netwkstausergetinfo,'+
    'netwkstausersetinfo,networkproc,newcompressor,newhiliter,newindex,newsearcher,'+
    'nextmatchintable,nfm_decompress,nfm_prepare,nfmcomp_create,nfmcomp_destroy,'+
    'nfmcompress,nfmcompress_init,nfmdeco_create,nfmdeco_destroy,ngetfontinfo,'+
    'ngetimetype,nhgetguidfrominterfacename,nhgetinterfacenamefromdeviceguid,'+
    'nhgetinterfacenamefromguid,nhpallocateandgetinterfaceinfofromstack,'+
    'nhpgetinterfaceindexfromstack,nlbindingsetauthinfo,nlsansicodepage,'+
    'nlsconvertintegertostring,nlsgetcacheupdatecount,nlsleadbyteinfo,'+
    'nlsmbcodepagetag,nlsmboemcodepagetag,nlsoemcodepage,nlsoemleadbyteinfo,'+
    'nlsresetprocesslocale,nmaddusedentry,nmcomboboxex,nmdatetimeformat,'+
    'nmdatetimestring,nmdatetimewmkeydown,nmheader,nmheapallocate,nmheapfree,'+
    'nmheapreallocate,nmheapsetmaxsize,nmheapsize,nmlvdispinfo,nmlvgetinfotip,'+
    'nmremoveusedentry,nmtbdispinfo,nmtbgetinfotip,nmtoolbar,nmttdispinfo,'+
    'nmtvgetinfotip,nocertificateenter,nocertificateremove,noenable,'+
    'nonasynceventthread,normalizeaddress,normalizeaddresstable,notifyaddrchange,'+
    'notifybootconfigstatus,notifycallbackdata,notifychangeeventlog,'+
    'notifyroutechange,notifyroutechangeex,notifywinevent,npaddconnection,'+
    'npaddconnection3,npaddconnection3forcscagent,npcancelconnectionforcscagent,'+
    'npcloseenum,npformatnetworkname,npgetconnection3,npgetconnectionperformance,'+
    'npgetdirectorytype,npgetpropertytext,npgetreconnectflags,'+
    'npgetresourceinformation,npgetresourceparent,npgetuser,nploadnamespaces,'+
    'nppropertydialog,nrandom,nrqsorta,nrqsortd,nseed,ntacceptconnectport,'+
    'ntaccesscheck,ntaccesscheckandauditalarm,ntaccesscheckbytype,'+
    'ntaccesscheckbytypeandauditalarm,ntaccesscheckbytyperesultlist,'+
    'ntaccesscheckbytyperesultlistandauditalarm'+
    'ntaccesscheckbytyperesultlistandauditalarmbyhandle,ntacslan,ntaddatom,'+
    'ntaddbootentry,ntadjustgroupstoken,ntadjustprivilegestoken,ntalertresumethread,'+
    'ntalertthread,ntallocatelocallyuniqueid,ntallocateuserphysicalpages,'+
    'ntallocateuuids,ntallocatevirtualmemory,ntapmclassinstaller,'+
    'ntaremappedfilesthesame,ntassignprocesstojobobject,ntbuildnumber,'+
    'ntcallbackreturn,ntcanceldevicewakeuprequest,ntcanceliofile,ntcanceltimer,'+
    'ntclearevent,ntclose,ntcloseobjectauditalarm,ntcompactkeys,ntcomparetokens,'+
    'ntcompleteconnectport,ntcompresskey,ntconnectport,ntcontinue,'+
    'ntcreatedebugobject,ntcreatedirectoryobject,ntcreateevent,ntcreateeventpair,'+
    'ntcreatefile,ntcreateiocompletion,ntcreatejobobject,ntcreatejobset,ntcreatekey,'+
    'ntcreatekeyedevent,ntcreatemailslotfile,ntcreatemutant,ntcreatenamedpipefile,'+
    'ntcreatepagingfile,ntcreateport,ntcreateprocess,ntcreateprocessex,'+
    'ntcreateprofile,ntcreatesection,ntcreatesemaphore,ntcreatesymboliclinkobject,'+
    'ntcreatethread,ntcreatetimer,ntcreatetoken,ntcreatewaitableport,ntcurrentteb,'+
    'ntdebugactiveprocess,ntdebugcontinue,ntdelayexecution,ntdeleteatom,'+
    'ntdeletebootentry,ntdeletefile,ntdeletekey,ntdeleteobjectauditalarm,'+
    'ntdeletevaluekey,ntdeviceiocontrolfile,ntdisplaystring,ntdsdemote,'+
    'ntdsfreednsrrinfo,ntdsgetdefaultdnsname,ntdsinstall,ntdsinstallcancel,'+
    'ntdsinstallreplicatefull,ntdsinstallshutdown,ntdsinstallundo,'+
    'ntdspconfigregistry,ntdspdnstorfc1779name,ntdspfindsite,ntdspreparefordemotion,'+
    'ntdspreparefordemotionundo,ntdspreparefordsupgrade,'+
    'ntdspvalidateinstallparameters,ntdspverifydsenvironment,'+
    'ntdssetreplicamachineaccount,ntduplicateobject,ntduplicatetoken,'+
    'ntenumeratebootentries,ntenumeratekey,ntenumeratesystemenvironmentvaluesex,'+
    'ntenumeratevaluekey,ntextendsection,ntfiltertoken,ntfindatom,ntflushbuffersfile,'+
    'ntflushinstructioncache,ntflushkey,ntflushvirtualmemory,ntflushwritebuffer,'+
    'ntfreeuserphysicalpages,ntfreevirtualmemory,ntfrsapi_abortdemotion,'+
    'ntfrsapi_abortdemotionw,ntfrsapi_abortpromotion,ntfrsapi_abortpromotionw,'+
    'ntfrsapi_commitdemotion,ntfrsapi_commitdemotionw,ntfrsapi_commitpromotion,'+
    'ntfrsapi_commitpromotionw,ntfrsapi_deletesysvolmember,'+
    'ntfrsapi_get_dspollinginterval,ntfrsapi_get_dspollingintervalw,ntfrsapi_info,'+
    'ntfrsapi_infofree,ntfrsapi_infofreew,ntfrsapi_infoline,ntfrsapi_infolinew,'+
    'ntfrsapi_infomore,ntfrsapi_infomorew,ntfrsapi_infow,ntfrsapi_initialize,'+
    'ntfrsapi_preparefordemotion,ntfrsapi_preparefordemotionusingcred,'+
    'ntfrsapi_preparefordemotionusingcredw,ntfrsapi_preparefordemotionw,'+
    'ntfrsapi_prepareforpromotion,ntfrsapi_prepareforpromotionw,'+
    'ntfrsapi_set_dspollinginterval,ntfrsapi_set_dspollingintervalw,'+
    'ntfrsapi_startdemotion,ntfrsapi_startdemotionw,ntfrsapi_startpromotion,'+
    'ntfrsapi_startpromotionw,ntfrsapi_waitfordemotion,ntfrsapi_waitfordemotionw,'+
    'ntfrsapi_waitforpromotion,ntfrsapi_waitforpromotionw,'+
    'ntfrsapidestroybackuprestore,ntfrsapienumbackuprestoresets,'+
    'ntfrsapifinishedrestoringdirectory,ntfrsapigetbackuprestoresetdirectory,'+
    'ntfrsapigetbackuprestoresetpaths,ntfrsapigetbackuprestoresets,'+
    'ntfrsapiinitializebackuprestore,ntfrsapiisbackuprestoresetasysvol,'+
    'ntfrsapirestoringdirectory,ntfscontrolfile,ntgetcontextthread,'+
    'ntgetdevicepowerstate,ntgetplugplayevent,ntgetwritewatch,ntglobalflag,'+
    'ntimpersonateanonymoustoken,ntimpersonateclientofport,ntimpersonatethread,'+
    'ntinitializeregistry,ntinitiatepoweraction,ntisprocessinjob,'+
    'ntissystemresumeautomatic,ntlicenserequesta,ntlistenport,ntloaddriver,ntloadkey,'+
    'ntloadkey2,ntlockfile,ntlockproductactivationkeys,ntlockregistrykey,'+
    'ntlockvirtualmemory,ntlsfreehandle,ntmakepermanentobject,ntmaketemporaryobject,'+
    'ntmapuserphysicalpages,ntmapuserphysicalpagesscatter,ntmapviewofsection,'+
    'ntmodifybootentry,ntnotifychangedirectoryfile,ntnotifychangekey,'+
    'ntnotifychangemultiplekeys,ntohl,ntohs,ntopendirectoryobject,ntopenevent,'+
    'ntopeneventpair,ntopenfile,ntopeniocompletion,ntopenjobobject,ntopenkey,'+
    'ntopenkeyedevent,ntopenmutant,ntopenobjectauditalarm,ntopenprocess,'+
    'ntopenprocesstoken,ntopenprocesstokenex,ntopensection,ntopensemaphore,'+
    'ntopensymboliclinkobject,ntopenthread,ntopenthreadtoken,ntopenthreadtokenex,'+
    'ntopentimer,ntplugplaycontrol,ntpowerinformation,ntprivilegecheck,'+
    'ntprivilegedserviceauditalarm,ntprivilegeobjectauditalarm,'+
    'ntprotectvirtualmemory,ntptimetontfiletime,ntpulseevent,ntqueryattributesfile,'+
    'ntquerybootentryorder,ntquerybootoptions,ntquerydebugfilterstate,'+
    'ntquerydefaultlocale,ntquerydefaultuilanguage,ntquerydirectoryfile,'+
    'ntquerydirectoryobject,ntqueryeafile,ntqueryevent,ntqueryfullattributesfile,'+
    'ntqueryinformationatom,ntqueryinformationfile,ntqueryinformationjobobject,'+
    'ntqueryinformationport,ntqueryinformationprocess,ntqueryinformationthread,'+
    'ntqueryinformationtoken,ntqueryinstalluilanguage,ntqueryintervalprofile,'+
    'ntqueryiocompletion,ntquerykey,ntquerymultiplevaluekey,ntquerymutant,'+
    'ntqueryobject,ntqueryopensubkeys,ntqueryperformancecounter,'+
    'ntqueryportinformationprocess,ntqueryquotainformationfile,ntquerysection,'+
    'ntquerysecurityobject,ntquerysemaphore,ntquerysymboliclinkobject,'+
    'ntquerysystemenvironmentvalue,ntquerysystemenvironmentvalueex,'+
    'ntquerysysteminformation,ntquerysystemtime,ntquerytimer,ntquerytimerresolution,'+
    'ntqueryvaluekey,ntqueryvirtualmemory,ntqueryvolumeinformationfile,'+
    'ntqueueapcthread,ntraiseexception,ntraiseharderror,ntreadfile,ntreadfilescatter,'+
    'ntreadrequestdata,ntreadvirtualmemory,ntregisterthreadterminateport,'+
    'ntreleasekeyedevent,ntreleasemutant,ntreleasesemaphore,ntremoveiocompletion,'+
    'ntremoveprocessdebug,ntrenamekey,ntreplacekey,ntreplyport,'+
    'ntreplywaitreceiveport,ntreplywaitreceiveportex,ntreplywaitreplyport,'+
    'ntrequestdevicewakeup,ntrequestport,ntrequestwaitreplyport,'+
    'ntrequestwakeuplatency,ntresetevent,ntresetwritewatch,ntrestorekey,'+
    'ntresumeprocess,ntresumethread,ntsavekey,ntsavekeyex,ntsavemergedkeys,'+
    'ntsecureconnectport,ntsetbootentryorder,ntsetbootoptions,ntsetcontextthread,'+
    'ntsetdebugfilterstate,ntsetdefaultharderrorport,ntsetdefaultlocale,'+
    'ntsetdefaultuilanguage,ntseteafile,ntsetevent,ntseteventboostpriority,'+
    'ntsethigheventpair,ntsethighwaitloweventpair,ntsetinformationdebugobject,'+
    'ntsetinformationfile,ntsetinformationjobobject,ntsetinformationkey,'+
    'ntsetinformationobject,ntsetinformationprocess,ntsetinformationthread,'+
    'ntsetinformationtoken,ntsetintervalprofile,ntsetiocompletion,ntsetldtentries,'+
    'ntsetloweventpair,ntsetlowwaithigheventpair,ntsetquotainformationfile,'+
    'ntsetsecurityobject,ntsetsystemenvironmentvalue,ntsetsystemenvironmentvalueex,'+
    'ntsetsysteminformation,ntsetsystempowerstate,ntsetsystemtime,'+
    'ntsetthreadexecutionstate,ntsettimer,ntsettimerresolution,ntsetuuidseed,'+
    'ntsetvaluekey,ntsetvolumeinformationfile,ntshutdownsystem,'+
    'ntsignalandwaitforsingleobject,ntstartprofile,ntstopprofile,ntsuspendprocess,'+
    'ntsuspendthread,ntsystemdebugcontrol,ntterminatejobobject,ntterminateprocess,'+
    'ntterminatethread,nttestalert,nttimetontptime,nttraceevent,nttranslatefilepath,'+
    'ntunloaddriver,ntunloadkey,ntunloadkeyex,ntunlockfile,ntunlockvirtualmemory,'+
    'ntunmapviewofsection,ntvdmcontrol,ntwaitfordebugevent,ntwaitforkeyedevent,'+
    'ntwaitformultipleobjects,ntwaitforsingleobject,ntwaithigheventpair,'+
    'ntwaitloweventpair,ntwritefile,ntwritefilegather,ntwriterequestdata,'+
    'ntwritevirtualmemory,ntyieldexecution,nuketempfiles,nullscaler,'+
    'numavirtualquerynode,nvgetdecodeproclist,nvgetdecodeprocnum,nvgetencodeproclist,'+
    'nvgetencodeprocnum,nwaddright,nwchecktrusteerights,nwremoveright,nwscantrustees,'+
    'oabuildversion,oacreatetypelib2,obassignsecurity,obcheckcreateobjectaccess,'+
    'obcheckobjectaccess,obclosehandle,obcreateobject,obcreateobjecttype,'+
    'obdeletecapturedinsertinfo,obdereferenceobject,obdereferencesecuritydescriptor,'+
    'obfindhandleforobject,obgetobjectsecurity,obinsertobject,'+
    'objectclassfromsearchcolumn,objectcloseauditalarm,objectcloseauditalarma,'+
    'objectcloseauditalarmw,objectdeleteauditalarm,objectdeleteauditalarma,'+
    'objectdeleteauditalarmw,objectfromlresult,objectidentifiercontains,'+
    'objectopenauditalarm,objectopenauditalarma,objectopenauditalarmw,'+
    'objectprivilegeauditalarm,objectprivilegeauditalarma,objectprivilegeauditalarmw,'+
    'objqueryname,objquerysize,objquerytype,objrename,oblogsecuritydescriptor,'+
    'obmaketemporaryobject,obopenobjectbyname,obopenobjectbypointer,'+
    'obquerynamestring,obqueryobjectauditingbyhandle,obreferenceobjectbyhandle,'+
    'obreferenceobjectbyname,obreferenceobjectbypointer,'+
    'obreferencesecuritydescriptor,obreleaseobjectsecurity,obsethandleattributes,'+
    'obsetsecuritydescriptorinfo,obsetsecurityobjectbypointer,obtainuseragentstring,'+
    'ocm,odbcgettrywaitvalue,odbcinternalconnect,odbcinternalconnectw,'+
    'odbcqualifyfiledsn,odbcqualifyfiledsnw,odbcsettrywaitvalue,oemkeyscan,oemtochar,'+
    'oemtochara,oemtocharbuff,oemtocharbuffa,oemtocharbuffw,oemtocharw,ofcallback,'+
    'officecleanuppolicy,officeinitializepolicy,offlineclustergroup,'+
    'offlineclusterresource,offsetcliprgn,offsetrect,offsetrgn,offsetviewportorgex,'+
    'offsetwindoworgex,oldgetprinterdriver,oldgetprinterdriverw,oleactivate,'+
    'oleblockserver,olebuildversion,oleclone,oleclose,oleconvertistoragetoolestream,'+
    'oleconvertistoragetoolestreamex,oleconvertolestreamtoistorage,'+
    'oleconvertolestreamtoistorageex,olecopyfromlink,olecopytoclipboard,olecreate,'+
    'olecreatedefaulthandler,olecreateembeddinghelper,olecreateex,'+
    'olecreatefontindirect,olecreatefromclip,olecreatefromdata,olecreatefromdataex,'+
    'olecreatefromfile,olecreatefromfileex,olecreatefromtemplate,olecreateinvisible,'+
    'olecreatelink,olecreatelinkex,olecreatelinkfromclip,olecreatelinkfromdata,'+
    'olecreatelinkfromdataex,olecreatelinkfromfile,olecreatelinktofile,'+
    'olecreatelinktofileex,olecreatemenudescriptor,olecreatepictureindirect,'+
    'olecreatepropertyframe,olecreatepropertyframeindirect,olecreatestaticfromdata,'+
    'oledelete,oledestroymenudescriptor,oledoautoconvert,oledraw,oleduplicatedata,'+
    'oleenumformats,oleenumobjects,oleequal,oleexecute,oleflushclipboard,'+
    'olegetautoconvert,olegetclipboard,olegetdata,olegeticonofclass,olegeticonoffile,'+
    'olegetlinkupdateoptions,oleicontocursor,oleinitialize,oleinitializewo,'+
    'oleinitializewow,oleiscurrentclipboard,oleisdcmeta,oleisrunning,oleload,'+
    'oleloadfromstream,oleloadpicture,oleloadpictureex,oleloadpicturefile,'+
    'oleloadpicturefileex,oleloadpicturepath,olelockrunning,olelockserver,'+
    'olemetafilepictfromiconandlabel,olenoteobjectvisible,oleobjectconvert,'+
    'olequerybounds,olequeryclientversion,olequerycreatefromclip,'+
    'olequerycreatefromdata,olequerylinkfromclip,olequerylinkfromdata,olequeryname,'+
    'olequeryobjpos,olequeryopen,olequeryoutofdate,olequeryprotocol,'+
    'olequeryreleaseerror,olequeryreleasemethod,olequeryreleasestatus,'+
    'olequeryserverversion,olequerysize,olequerytype,olereconnect,'+
    'oleregenumformatetc,oleregenumverbs,olereggetmiscstatus,olereggetusertype,'+
    'oleregisterclientdoc,oleregisterserver,oleregisterserverdoc,olerelease,'+
    'olerename,olerenameclientdoc,olerenameserverdoc,olerequestdata,'+
    'olerevertclientdoc,olerevertserverdoc,olerevokeclientdoc,olerevokeobject,'+
    'olerevokeserver,olerevokeserverdoc,olerun,olesave,olesavedclientdoc,'+
    'olesavedserverdoc,olesavepicturefile,olesavetostream,olesavetostreamex,'+
    'olesetautoconvert,olesetbounds,olesetclipboard,olesetcolorscheme,'+
    'olesetcontainedobject,olesetdata,olesethostnames,olesetlinkupdateoptions,'+
    'olesetmenudescriptor,olesettargetdevice,oletranslateaccelerator,'+
    'oletranslatecolor,oleuiaddverbmenu,oleuiaddverbmenua,oleuiaddverbmenuw,'+
    'oleuibusy,oleuibusya,oleuibusyw,oleuicanconvertoractivateas,oleuichangeicon,'+
    'oleuichangeicona,oleuichangeiconw,oleuichangesource,oleuichangesourcea,'+
    'oleuichangesourcew,oleuiconvert,oleuiconverta,oleuiconvertw,oleuieditlinks,'+
    'oleuieditlinksa,oleuieditlinksw,oleuiinsertobject,oleuiinsertobjecta,'+
    'oleuiinsertobjectw,oleuiobjectproperties,oleuiobjectpropertiesa,'+
    'oleuiobjectpropertiesw,oleuipastespecial,oleuipastespeciala,oleuipastespecialw,'+
    'oleuipromptuser,oleuipromptusera,oleuipromptuserw,oleuiupdatelinks,'+
    'oleuiupdatelinksa,oleuiupdatelinksw,oleunblockserver,oleuninitialize,'+
    'oleunlockserver,oleupdate,onlineclustergroup,onlineclusterresource,open,'+
    'open_printer_props_info,openbackupeventlog,openbackupeventloga,'+
    'openbackupeventlogw,openbiditabdialog,openclipboard,opencluster,'+
    'openclustergroup,openclusternetinterface,openclusternetwork,openclusternode,'+
    'openclusterresource,opencolorprofile,opencolorprofilea,opencolorprofilew,'+
    'openconsole,openconsolew,opendatafile,opendesktop,opendesktopa,opendesktopw,'+
    'opendialog,opendir,opendnsperformancedata,opendriver,openencryptedfileraw,'+
    'openencryptedfilerawa,openencryptedfileraww,openevent,openeventa,openeventlog,'+
    'openeventloga,openeventlogw,openeventw,openfile,openfiledialog,openfilemapping,'+
    'openfilemappinga,openfilemappingw,openfilename,openicon,openimsgonistg,'+
    'openimsgsession,openindex,openinfengine,openinputdesktop,openjobobject,'+
    'openjobobjecta,openjobobjectw,openmutex,openmutexa,openmutexw,'+
    'openncpsrvperformancedata,opennetwork,openntmsnotification,openntmssession,'+
    'openntmssessiona,openntmssessionw,openodbcperfdata,openorcreatestream,'+
    'openpersonaltrustdbdialog,openpersonaltrustdbdialogex,openport,openprinter,'+
    'openprintera,openprinterex,openprinterexw,openprinterport,openprinterportw,'+
    'openprinterw,openprintprocessor,openprocess,openprocesstoken,'+
    'openprofileusermapping,openregstream,openscmanager,openscmanagera,'+
    'openscmanagerw,opensemaphore,opensemaphorea,opensemaphorew,openservice,'+
    'openservicea,openservicew,opensslperformancedata,openstream,openstreamonfile,'+
    'opentabdialog,openthemedata,openthread,openthreadtoken,opentnefstream,'+
    'opentnefstreamex,opentrace,opentracea,opentracew,openuserbrowser,'+
    'openwaitabletimer,openwaitabletimera,openwaitabletimerw,openwindowstation,'+
    'openwindowstationa,openwindowstationw,opkcheckversion,opt_encode_top,'+
    'orexpression,osversioninfoex,output_bits,output_block,outputdebugstring,'+
    'outputdebugstringa,outputdebugstringw,overlap,packddelparam,packstrings,'+
    'pagesetupdialog,pagesetupdlg,pagesetupdlga,pagesetupdlgw,paintdesktop,paintrgn,'+
    'palobj_cgetcolors,panicmessage,parallelportproppageprovider,parse_line,'+
    'parsertemporarylockframe,parsex509encodedcertificateforlistboxentry,partial,'+
    'partialreplyprinterchangenotification,pasync,patblt,pathaddbackslash,'+
    'pathaddbackslasha,pathaddbackslashw,pathaddextension,pathaddextensiona,'+
    'pathaddextensionw,pathappend,pathappenda,pathappendw,pathbuildroot,'+
    'pathbuildroota,pathbuildrootw,pathcanonicalize,pathcanonicalizea,'+
    'pathcanonicalizew,pathcleanupspec,pathcombine,pathcombinea,pathcombinew,'+
    'pathcommonprefix,pathcommonprefixa,pathcommonprefixw,pathcompactpath,'+
    'pathcompactpatha,pathcompactpathex,pathcompactpathexa,pathcompactpathexw,'+
    'pathcompactpathw,pathconf,pathcreatefromurl,pathcreatefromurla,'+
    'pathcreatefromurlw,pathfileexists,pathfileexistsa,pathfileexistsw,'+
    'pathfindextension,pathfindextensiona,pathfindextensionw,pathfindfilename,'+
    'pathfindfilenamea,pathfindfilenamew,pathfindnextcomponent,'+
    'pathfindnextcomponenta,pathfindnextcomponentw,pathfindonpath,pathfindonpatha,'+
    'pathfindonpathw,pathfindsuffixarray,pathfindsuffixarraya,pathfindsuffixarrayw,'+
    'pathgetargs,pathgetargsa,pathgetargsw,pathgetchartype,pathgetchartypea,'+
    'pathgetchartypew,pathgetdrivenumber,pathgetdrivenumbera,pathgetdrivenumberw,'+
    'pathgetshortpath,pathiscontenttype,pathiscontenttypea,pathiscontenttypew,'+
    'pathisdirectory,pathisdirectorya,pathisdirectoryempty,pathisdirectoryemptya,'+
    'pathisdirectoryemptyw,pathisdirectoryw,pathisexe,pathisfilespec,pathisfilespeca,'+
    'pathisfilespecw,pathislfnfilespec,pathislfnfilespeca,pathislfnfilespecw,'+
    'pathisnetworkpath,pathisnetworkpatha,pathisnetworkpathw,pathisprefix,'+
    'pathisprefixa,pathisprefixw,pathisrelative,pathisrelativea,pathisrelativew,'+
    'pathisroot,pathisroota,pathisrootw,pathissameroot,pathissameroota,'+
    'pathissamerootw,pathisslow,pathisslowa,pathissloww,pathissystemfolder,'+
    'pathissystemfoldera,pathissystemfolderw,pathisunc,pathisunca,pathisuncserver,'+
    'pathisuncservera,pathisuncservershare,pathisuncserversharea,'+
    'pathisuncserversharew,pathisuncserverw,pathisuncw,pathisurl,pathisurla,'+
    'pathisurlw,pathmakepretty,pathmakeprettya,pathmakeprettyw,pathmakesystemfolder,'+
    'pathmakesystemfoldera,pathmakesystemfolderw,pathmakeuniquename,pathmatchspec,'+
    'pathmatchspeca,pathmatchspecw,pathobj_bclosefigure,pathobj_benum,'+
    'pathobj_benumcliplines,pathobj_bmoveto,pathobj_bpolybezierto,'+
    'pathobj_bpolylineto,pathobj_venumstart,pathobj_venumstartcliplines,'+
    'pathobj_vgetbounds,pathparseiconlocation,pathparseiconlocationa,'+
    'pathparseiconlocationw,pathprocesscommand,pathqualify,pathquotespaces,'+
    'pathquotespacesa,pathquotespacesw,pathrelativepathto,pathrelativepathtoa,'+
    'pathrelativepathtow,pathremoveargs,pathremoveargsa,pathremoveargsw,'+
    'pathremovebackslash,pathremovebackslasha,pathremovebackslashw,pathremoveblanks,'+
    'pathremoveblanksa,pathremoveblanksw,pathremoveextension,pathremoveextensiona,'+
    'pathremoveextensionw,pathremovefilespec,pathremovefilespeca,pathremovefilespecw,'+
    'pathrenameextension,pathrenameextensiona,pathrenameextensionw,pathresolve,'+
    'pathsearchandqualify,pathsearchandqualifya,pathsearchandqualifyw,'+
    'pathsetdlgitempath,pathsetdlgitempatha,pathsetdlgitempathw,pathskiproot,'+
    'pathskiproota,pathskiprootw,pathstrippath,pathstrippatha,pathstrippathw,'+
    'pathstriptoroot,pathstriptoroota,pathstriptorootw,pathtoregion,pathundecorate,'+
    'pathundecoratea,pathundecoratew,pathunexpandenvstrings,pathunexpandenvstringsa,'+
    'pathunexpandenvstringsw,pathunmakesystemfolder,pathunmakesystemfoldera,'+
    'pathunmakesystemfolderw,pathunquotespaces,pathunquotespacesa,pathunquotespacesw,'+
    'pathyetanothermakeuniquename,pause,pausecapturing,pauseclusternode,'+
    'pbcopytoclipboard,pbcreate,pbcreatefromclip,pbcreatefromfile,'+
    'pbcreatefromtemplate,pbcreateinvisible,pbcreatelinkfromclip,'+
    'pbcreatelinkfromfile,pbdraw,pbenumformats,pbgetdata,pbloadfromstream,'+
    'pbquerybounds,pcacquireformatresources,pcaddadapterdevice,pcaddcontenthandlers,'+
    'pcaddtoeventtable,pcaddtopropertytable,pccaptureformat,pccompleteirp,'+
    'pccompletependingeventrequest,pccompletependingpropertyrequest,'+
    'pccreatecontentmixed,pccreatesubdevicedescriptor,pcdeletesubdevicedescriptor,'+
    'pcdestroycontent,pcdispatchirp,pcdmamasterdescription,pcdmaslavedescription,'+
    'pcforwardcontenttodeviceobject,pcforwardcontenttofileobject,'+
    'pcforwardcontenttointerface,pcforwardirpsynchronous,pcfreeeventtable,'+
    'pcfreepropertytable,pcgenerateeventdeferredroutine,pcgenerateeventlist,'+
    'pcgetcontentrights,pcgetdeviceproperty,pcgettimeinterval,'+
    'pchandledisableeventwithtable,pchandleenableeventwithtable,'+
    'pchandlepropertywithtable,pciidexdebugprint,pciidexgetbusdata,pciidexinitialize,'+
    'pciidexsetbusdata,pcinitializeadapterdriver,pcnewdmachannel,pcnewinterruptsync,'+
    'pcnewminiport,pcnewport,pcnewregistrykey,pcnewresourcelist,pcnewresourcesublist,'+
    'pcnewservicegroup,pcpinpropertyhandler,pcregisteradapterpowermanagement,'+
    'pcregisteriotimeout,pcregisterphysicalconnection,'+
    'pcregisterphysicalconnectionfromexternal,pcregisterphysicalconnectiontoexternal,'+
    'pcregistersubdevice,pcrequestnewpowerstate,pcterminateconnection,'+
    'pcunregisteriotimeout,pcvalidateconnectrequest,pcverifyfilterisready,'+
    'pdevicechain,pdhaddcounter,pdhaddcountera,pdhaddcounterw,pdhbindinputdatasource,'+
    'pdhbindinputdatasourcea,pdhbindinputdatasourcew,pdhbrowsecounters,'+
    'pdhbrowsecountersa,pdhbrowsecountersh,pdhbrowsecountersha,pdhbrowsecountershw,'+
    'pdhbrowsecountersw,pdhcalculatecounterfromrawvalue,pdhcloselog,pdhclosequery,'+
    'pdhcollectquerydata,pdhcollectquerydataex,pdhcomputecounterstatistics,'+
    'pdhconnectmachine,pdhconnectmachinea,pdhconnectmachinew,pdhcreatesqltables,'+
    'pdhcreatesqltablesa,pdhcreatesqltablesw,pdhenumlogsetnames,pdhenumlogsetnamesa,'+
    'pdhenumlogsetnamesw,pdhenummachines,pdhenummachinesa,pdhenummachinesh,'+
    'pdhenummachinesha,pdhenummachineshw,pdhenummachinesw,pdhenumobjectitems,'+
    'pdhenumobjectitemsa,pdhenumobjectitemsh,pdhenumobjectitemsha,'+
    'pdhenumobjectitemshw,pdhenumobjectitemsw,pdhenumobjects,pdhenumobjectsa,'+
    'pdhenumobjectsh,pdhenumobjectsha,pdhenumobjectshw,pdhenumobjectsw,'+
    'pdhexpandcounterpath,pdhexpandcounterpatha,pdhexpandcounterpathw,'+
    'pdhexpandwildcardpath,pdhexpandwildcardpatha,pdhexpandwildcardpathh,'+
    'pdhexpandwildcardpathha,pdhexpandwildcardpathhw,pdhexpandwildcardpathw,'+
    'pdhformatfromrawvalue,pdhgetcounterinfo,pdhgetcounterinfoa,pdhgetcounterinfow,'+
    'pdhgetcountertimebase,pdhgetdatasourcetimerange,pdhgetdatasourcetimerangea,'+
    'pdhgetdatasourcetimerangeh,pdhgetdatasourcetimerangew,pdhgetdefaultperfcounter,'+
    'pdhgetdefaultperfcountera,pdhgetdefaultperfcounterh,pdhgetdefaultperfcounterha,'+
    'pdhgetdefaultperfcounterhw,pdhgetdefaultperfcounterw,pdhgetdefaultperfobject,'+
    'pdhgetdefaultperfobjecta,pdhgetdefaultperfobjecth,pdhgetdefaultperfobjectha,'+
    'pdhgetdefaultperfobjecthw,pdhgetdefaultperfobjectw,pdhgetdllversion,'+
    'pdhgetformattedcounterarray,pdhgetformattedcounterarraya,'+
    'pdhgetformattedcounterarrayw,pdhgetformattedcountervalue,pdhgetlogfilesize,'+
    'pdhgetlogsetguid,pdhgetrawcounterarray,pdhgetrawcounterarraya,'+
    'pdhgetrawcounterarrayw,pdhgetrawcountervalue,pdhisrealtimequery,'+
    'pdhlogservicecommand,pdhlogservicecommanda,pdhlogservicecommandw,'+
    'pdhlogservicecontrol,pdhlogservicecontrola,pdhlogservicecontrolw,'+
    'pdhlookupperfindexbyname,pdhlookupperfindexbynamea,pdhlookupperfindexbynamew,'+
    'pdhlookupperfnamebyindex,pdhlookupperfnamebyindexa,pdhlookupperfnamebyindexw,'+
    'pdhmakecounterpath,pdhmakecounterpatha,pdhmakecounterpathw,pdhopenlog,'+
    'pdhopenloga,pdhopenlogw,pdhopenquery,pdhopenquerya,pdhopenqueryh,pdhopenqueryw,'+
    'pdhparsecounterpath,pdhparsecounterpatha,pdhparsecounterpathw,'+
    'pdhparseinstancename,pdhparseinstancenamea,pdhparseinstancenamew,'+
    'pdhreadrawlogrecord,pdhremovecounter,pdhselectdatasource,pdhselectdatasourcea,'+
    'pdhselectdatasourcew,pdhsetcounterscalefactor,pdhsetdefaultrealtimedatasource,'+
    'pdhsetlogsetrunid,pdhsetquerytimerange,pdhupdatelog,pdhupdateloga,'+
    'pdhupdatelogfilecatalog,pdhupdatelogw,pdhvalidatepath,pdhvalidatepatha,'+
    'pdhvalidatepathw,pdhvbaddcounter,pdhvbcreatecounterpathlist,'+
    'pdhvbgetcounterpathelements,pdhvbgetcounterpathfromlist,'+
    'pdhvbgetdoublecountervalue,pdhvbgetlogfilesize,pdhvbgetonecounterpath,'+
    'pdhvbisgoodstatus,pdhvbopenlog,pdhvbopenquery,pdhvbupdatelog,pdhverifysqldb,'+
    'pdhverifysqldba,pdhverifysqldbw,peekconsoleinput,peekconsoleinputa,'+
    'peekconsoleinputw,peekmessage,peekmessagea,peekmessagew,peeknamedpipe,'+
    'perform_flush_output_callback,performoperationoverurlcachea,'+
    'pfaddfilterstointerface,pfaddglobalfiltertointerface,pfbindinterfacetoindex,'+
    'pfbindinterfacetoipaddress,pfcreateinterface,pfdeleteinterface,pfdeletelog,'+
    'pfgetinterfacestatistics,pfmakelog,pfnfreeroutines,pfnmarshallroutines,'+
    'pfnsizeroutines,pfrebindfilters,pfremovefilterhandles,'+
    'pfremovefiltersfrominterface,pfremoveglobalfilterfrominterface,pfsetlogbuffer,'+
    'pftestpacket,pfunbindinterface,pfxexportcertstore,pfxexportcertstoreex,'+
    'pfxfindprefix,pfximportcertstore,pfxinitialize,pfxinsertprefix,pfxispfxblob,'+
    'pfxremoveprefix,pfxverifypassword,phoneclose,phoneconfigdialog,'+
    'phoneconfigdialoga,phoneconfigdialogw,phonedevspecific,phonegetbuttoninfo,'+
    'phonegetbuttoninfoa,phonegetbuttoninfow,phonegetdata,phonegetdevcaps,'+
    'phonegetdevcapsa,phonegetdevcapsw,phonegetdisplay,phonegetgain,'+
    'phonegethookswitch,phonegeticon,phonegeticona,phonegeticonw,phonegetid,'+
    'phonegetida,phonegetidw,phonegetlamp,phonegetmessage,phonegetring,'+
    'phonegetstatus,phonegetstatusa,phonegetstatusmessages,phonegetstatusw,'+
    'phonegetvolume,phoneinitialize,phoneinitializeex,phoneinitializeexa,'+
    'phoneinitializeexw,phonenegotiateapiversion,phonenegotiateextversion,phoneopen,'+
    'phonesetbuttoninfo,phonesetbuttoninfoa,phonesetbuttoninfow,phonesetdata,'+
    'phonesetdisplay,phonesetgain,phonesethookswitch,phonesetlamp,phonesetring,'+
    'phonesetstatusmessages,phonesetvolume,phoneshutdown,pickicondlg,pie,'+
    'pifmgr_closeproperties,pifmgr_getproperties,pifmgr_openproperties,'+
    'pifmgr_setproperties,pingcomputer,pipe,pipedesc,pipemsg,pipestate,'+
    'playenhmetafile,playenhmetafilerecord,playgdiscriptonprinteric,playmetafile,'+
    'playmetafilerecord,playsound,playsounda,playsoundw,plgblt,'+
    'pnpinitializationthread,pocalldriver,pocanceldevicenotify,poll,polybezier,'+
    'polybezierto,polydraw,polygon,polyline,polylineto,polypolygon,polypolyline,'+
    'polytextout,polytextouta,polytextoutw,popupexpertconfigurationui,'+
    'poqueueshutdownworkitem,poregisterdeviceforidledetection,poregisterdevicenotify,'+
    'poregistersystemstate,porequestpowerirp,porequestshutdownevent,'+
    'portsclassinstaller,posethiberrange,posetpowerstate,posetsystemstate,'+
    'poshutdownbugcheck,postadspropsheet,postartnextpowerirp,postcomponenterror,'+
    'postmessage,postmessagea,postmessagew,postodbccomponenterror,postodbcerror,'+
    'postqueuedcompletionstatus,postquitmessage,postthreadmessage,postthreadmessagea,'+
    'postthreadmessagew,pounregistersystemstate,powercapabilities,ppropfindprop,'+
    'pqdownheap,prepareforaudit,preparetape,prevent_far_matches,printdialog,printdlg,'+
    'printdlga,printdlgex,printdlgexa,printdlgexw,printdlgw,'+
    'printdocumentonprintprocessor,printerhandlerundown,printermessagebox,'+
    'printermessageboxa,printermessageboxw,printerproperties,printf,'+
    'printuicreateinstance,printuidocumentdefaults,printuidocumentpropertieswrap,'+
    'printuiprinterproppages,printuiprintersetup,printuiqueuecreate,'+
    'printuiserverproppages,printuiwebpnpentry,printuiwebpnppostentry,printwindow,'+
    'privacygetzonepreference,privacygetzonepreferencew,privacysetzonepreference,'+
    'privacysetzonepreferencew,privateextracticons,privateextracticonsa,'+
    'privateextracticonsw,privcopyfileex,privcopyfileexw,privilegecheck,'+
    'privilegedserviceauditalarm,privilegedserviceauditalarma,'+
    'privilegedserviceauditalarmw,privmovefileidentity,privmovefileidentityw,'+
    'probeforread,probeforwrite,process32first,process32firstw,process32next,'+
    'process32nextw,processgrouppolicycompleted,processgrouppolicycompletedex,'+
    'processgrouppolicyobjectsex,processidletasks,processidtosessionid,processtrace,'+
    'progidfromclsid,prop_name_equals,propcopymore,property_name,propertysheet,'+
    'propertysheeta,propertysheetw,propstgnametofmtid,propsysallocstring,'+
    'propsysfreestring,propvariantclear,propvariantcopy,propvarianttoadstype,'+
    'propvarianttoadstype2,protocols,providorfindcloseprinterchangenotification,'+
    'providorfindfirstprinterchangenotification,prproviderinit,'+
    'ps2mouseproppageprovider,psassignimpersonationtoken,pschargepoolquota,'+
    'pschargeprocessnonpagedpoolquota,pschargeprocesspagedpoolquota,'+
    'pschargeprocesspoolquota,pscreatesystemprocess,pscreatesystemthread,'+
    'psdereferenceimpersonationtoken,psdereferenceprimarytoken,'+
    'psdisableimpersonation,psestablishwin32callouts,psetupdebugprint,'+
    'psetuplogsfcerror,psfcgetfileslist,psgetcontextthread,psgetcurrentprocess,'+
    'psgetcurrentprocessid,psgetcurrentprocesssessionid,'+
    'psgetcurrentprocesswin32process,psgetcurrentthread,psgetcurrentthreadid,'+
    'psgetcurrentthreadpreviousmode,psgetcurrentthreadprocess,'+
    'psgetcurrentthreadprocessid,psgetcurrentthreadstackbase,'+
    'psgetcurrentthreadstacklimit,psgetcurrentthreadteb,'+
    'psgetcurrentthreadwin32thread'+
    'psgetcurrentthreadwin32threadandentercriticalregion,psgetjoblock,'+
    'psgetjobsessionid,psgetjobuirestrictionsclass,psgetprocesscreatetimequadpart,'+
    'psgetprocessdebugport,psgetprocessexitprocesscalled,psgetprocessexitstatus,'+
    'psgetprocessexittime,psgetprocessid,psgetprocessimagefilename,'+
    'psgetprocessinheritedfromuniqueprocessid,psgetprocessjob,psgetprocesspeb,'+
    'psgetprocesspriorityclass,psgetprocesssectionbaseaddress,'+
    'psgetprocesssecurityport,psgetprocesssessionid,psgetprocesssessionidex,'+
    'psgetprocesswin32process,psgetprocesswin32windowstation,psgetthreadfreezecount,'+
    'psgetthreadharderrorsaredisabled,psgetthreadid,psgetthreadprocess,'+
    'psgetthreadprocessid,psgetthreadsessionid,psgetthreadteb,psgetthreadwin32thread,'+
    'psgetversion,psimpersonateclient,psinitialsystemprocess,'+
    'psisprocessbeingdebugged,psissystemprocess,psissystemthread,'+
    'psisthreadimpersonating,psisthreadterminating,psjobtype,'+
    'pslookupprocessbyprocessid,pslookupprocessthreadbycid,pslookupthreadbythreadid,'+
    'psprocesstype,psreferenceimpersonationtoken,psreferenceprimarytoken,'+
    'psremovecreatethreadnotifyroutine,psremoveloadimagenotifyroutine,'+
    'psrestoreimpersonation,psreturnpoolquota,psreturnprocessnonpagedpoolquota,'+
    'psreturnprocesspagedpoolquota,psrevertthreadtoself,psreverttoself,'+
    'pssetcontextthread,pssetcreateprocessnotifyroutine,'+
    'pssetcreatethreadnotifyroutine,pssetjobuirestrictionsclass,'+
    'pssetlegonotifyroutine,pssetloadimagenotifyroutine,pssetprocessprioritybyclass,'+
    'pssetprocesspriorityclass,pssetprocesssecurityport,pssetprocesswin32process,'+
    'pssetprocesswindowstation,pssetthreadharderrorsaredisabled,'+
    'pssetthreadwin32thread,psterminatesystemthread,psthreadtype,'+
    'pswrapapcwow64thread,pszdbgallocmsga,pticleanup,ptiinitialize,ptiisreadpending,'+
    'ptinrect,ptinregion,ptiportnamefromportid,ptiquerydevicestatus,'+
    'ptiquerymaxreadsize,ptiread,ptiregistercallbacks,ptiwrite,ptvisible,'+
    'publishprinter,publishprintera,publishprinterw,pullupmsg,pulseevent,purgecomm,'+
    'purgedownloaddirectory,purgeobjectheap,put,putbq,putctl,putctl1,putmsg,putnext,'+
    'putnextctl,putnextctl1,putq,putstringelement,putstringelementa,'+
    'putstringelementw,pvalue,qcontext,qenable,qreply,qsize,qsort,qssorta,qssortd,'+
    'qt_thunk,query_main,query_service_config,query_service_lock_status,queryactctx,'+
    'queryactctxw,queryalltraces,queryalltracesa,queryalltracesw,querycolorprofile,'+
    'querycontextattributes,querycontextattributesa,querycontextattributesw,'+
    'querycredentialsattributes,querycredentialsattributesa,'+
    'querycredentialsattributesw,querydepthslist,querydirectex,querydosdevice,'+
    'querydosdevicea,querydosdevicew,queryhilites,queryinformationjobobject,'+
    'querymemoryresourcenotification,querynetworkstatus,queryoptions,'+
    'querypathofregtypelib,queryperformancecounter,queryperformancefrequency,'+
    'queryprotocolstate,queryrecoveryagentsonencryptedfile,queryremotefonts,'+
    'querysecuritycontexttoken,querysecuritypackageinfo,querysecuritypackageinfoa,'+
    'querysecuritypackageinfow,queryserviceconfig,queryserviceconfig2,'+
    'queryserviceconfig2a,queryserviceconfig2w,queryserviceconfiga,'+
    'queryserviceconfigw,queryservicelockstatus,queryservicelockstatusa,'+
    'queryservicelockstatusw,queryserviceobjectsecurity,queryservicestatus,'+
    'queryservicestatusex,queryspoolmode,querytrace,querytracea,querytracew,'+
    'queryusersonencryptedfile,querywin31inifilesmappedtoregistry,'+
    'querywindows31filesmigration,queryworkingset,queue,queueuserapc,'+
    'queueuserworkitem,queueworkitem,quick_insert_bsearch_findmatch,quoterdnvalue,'+
    'raise,raiseexception,raisenmevent,rand,raparraylength,rapasciitodecimal,'+
    'rapauxdatacount,rapauxdatacountoffset,rapconvertsingleentry,'+
    'rapconvertsingleentryex,rapexaminedescriptor,rapgetfieldsize,'+
    'rapisvaliddescriptorsmb,raplastpointeroffset,rapparmnumdescriptor,'+
    'rapstructurealignment,rapstructuresize,raptotalsize,rasadmincompressphonenumber,'+
    'rasadminfreebuffer,rasadmingeterrorstring,rasadmingetuseraccountserver,'+
    'rasadmingetuserparms,rasadminportclearstatistics,rasadminportdisconnect,'+
    'rasadminportenum,rasadminportgetinfo,rasadminservergetinfo,rasadminsetuserparms,'+
    'rasadminusergetinfo,rasadminusersetinfo,rasautodialaddresstonetwork,'+
    'rasautodialdisabledlg,rasautodialdisabledlga,rasautodialdisabledlgw,'+
    'rasautodialentrytonetwork,rasautodialquerydlg,rasautodialquerydlga,'+
    'rasautodialquerydlgw,rasautodialsharedconnection,rasclearconnectionstatistics,'+
    'rasclearlinkstatistics,rasconnectionnotification,rasconnectionnotificationa,'+
    'rasconnectionnotificationw,rascreatephonebookentry,rascreatephonebookentrya,'+
    'rascreatephonebookentryw,rasdeleteentry,rasdeleteentrya,rasdeleteentryw,'+
    'rasdeletesubentry,rasdeletesubentrya,rasdeletesubentryw,rasdial,rasdiala,'+
    'rasdialdlg,rasdialdlga,rasdialdlgw,rasdialw,rasdialwow,raseditphonebookentry,'+
    'raseditphonebookentrya,raseditphonebookentryw,rasentrydlg,rasentrydlga,'+
    'rasentrydlgw,rasenumautodialaddresses,rasenumautodialaddressesa,'+
    'rasenumautodialaddressesw,rasenumconnections,rasenumconnectionsa,'+
    'rasenumconnectionsw,rasenumconnectionswow,rasenumdevices,rasenumdevicesa,'+
    'rasenumdevicesw,rasenumentries,rasenumentriesa,rasenumentriesw,'+
    'rasenumentrieswow,rasfileclose,rasfiledeleteline,rasfilefindfirstline,'+
    'rasfilefindlastline,rasfilefindmarkedline,rasfilefindnextkeyline,'+
    'rasfilefindnextline,rasfilefindprevline,rasfilefindsectionline,'+
    'rasfilegetkeyvaluefields,rasfilegetline,rasfilegetlinemark,rasfilegetlinetext,'+
    'rasfilegetlinetype,rasfilegetsectionname,rasfileinsertline,rasfileload,'+
    'rasfileloadinfo,rasfileputkeyvaluefields,rasfileputlinemark,rasfileputlinetext,'+
    'rasfileputsectionname,rasfilewrite,rasfreeeapuseridentity,'+
    'rasfreeeapuseridentitya,rasfreeeapuseridentityw,rasgetautodialaddress,'+
    'rasgetautodialaddressa,rasgetautodialaddressw,rasgetautodialenable,'+
    'rasgetautodialenablea,rasgetautodialenablew,rasgetautodialparam,'+
    'rasgetautodialparama,rasgetautodialparamw,rasgetconnectionstatistics,'+
    'rasgetconnectresponse,rasgetconnectstatus,rasgetconnectstatusa,'+
    'rasgetconnectstatusw,rasgetconnectstatuswow,rasgetcountryinfo,'+
    'rasgetcountryinfoa,rasgetcountryinfow,rasgetcredentials,rasgetcredentialsa,'+
    'rasgetcredentialsw,rasgetcustomauthdata,rasgetcustomauthdataa,'+
    'rasgetcustomauthdataw,rasgeteapuserdata,rasgeteapuserdataa,rasgeteapuserdataw,'+
    'rasgeteapuseridentity,rasgeteapuseridentitya,rasgeteapuseridentityw,'+
    'rasgetentrydialparams,rasgetentrydialparamsa,rasgetentrydialparamsw,'+
    'rasgetentryhrasconn,rasgetentryhrasconna,rasgetentryhrasconnw,'+
    'rasgetentryproperties,rasgetentrypropertiesa,rasgetentrypropertiesw,'+
    'rasgeterrorstring,rasgeterrorstringa,rasgeterrorstringw,rasgeterrorstringwow,'+
    'rasgethport,rasgetlinkstatistics,rasgetprojectioninfo,rasgetprojectioninfoa,'+
    'rasgetprojectioninfow,rasgetsubentryhandle,rasgetsubentryhandlea,'+
    'rasgetsubentryhandlew,rasgetsubentryproperties,rasgetsubentrypropertiesa,'+
    'rasgetsubentrypropertiesw,rashangup,rashangupa,rashangupw,rashangupwow,'+
    'rasinvokeeapui,rasisrouterconnection,rasissharedconnection,rasmonitordlg,'+
    'rasmonitordlga,rasmonitordlgw,rasphonebookdlg,rasphonebookdlga,rasphonebookdlgw,'+
    'rasprivilegeandcallbacknumber,rasqueryredialonlinkfailure,'+
    'rasquerysharedautodial,rasquerysharedconnection,rasrenameentry,rasrenameentrya,'+
    'rasrenameentryw,rasscriptexecute,rasscriptgeteventcode,rasscriptgetipaddress,'+
    'rasscriptinit,rasscriptreceive,rasscriptsend,rasscriptterm,'+
    'rassetautodialaddress,rassetautodialaddressa,rassetautodialaddressw,'+
    'rassetautodialenable,rassetautodialenablea,rassetautodialenablew,'+
    'rassetautodialparam,rassetautodialparama,rassetautodialparamw,rassetcredentials,'+
    'rassetcredentialsa,rassetcredentialsw,rassetcustomauthdata,'+
    'rassetcustomauthdataa,rassetcustomauthdataw,rasseteapuserdata,'+
    'rasseteapuserdataa,rasseteapuserdataw,rassetentrydialparams,'+
    'rassetentrydialparamsa,rassetentrydialparamsw,rassetentryproperties,'+
    'rassetentrypropertiesa,rassetentrypropertiesw,rassetoldpassword,'+
    'rassetsharedautodial,rassetsubentryproperties,rassetsubentrypropertiesa,'+
    'rassetsubentrypropertiesw,rassrvaddproppages,rassrvaddwizpages,'+
    'rassrvallowconnectionsconfig,rassrvcleanupservice,rassrvenumconnections,'+
    'rassrvhangupconnection,rassrvinitializeservice,rassrvisconnectionconnected,'+
    'rassrvisservicerunning,rassrvqueryshowicon,rasuserenablemanualdial,'+
    'rasusergetmanualdial,rasuserprefsdlg,rasvalidateentryname,rasvalidateentrynamea,'+
    'rasvalidateentrynamew,raswizcreatenewentry,raswizgetnccflags,'+
    'raswizgetsuggestedentryname,raswizgetuserinputconnectionname,'+
    'raswizisentryrenamable,raswizquerymaxpagecount,raswizsetentryname,'+
    'ratingaccessdenieddialog,ratingaccessdenieddialog2,ratingaddpropertypages,'+
    'ratingcheckuseraccess,ratingcustomaddratinghelper,ratingcustomaddratingsystem,'+
    'ratingcustomcrackdata,ratingcustomdeletecrackeddata,ratingcustominit,'+
    'ratingcustomremoveratinghelper,ratingcustomsetdefaultbureau,'+
    'ratingcustomsetuseroptions,ratingenable,ratingenabledquery,ratingfreedetails,'+
    'ratinginit,ratingobtaincancel,ratingobtainquery,ratingsetupui,rcmd,read,'+
    'read_aligned_offset_tree,read_disk_file,read_disk_filew,read_file_in,'+
    'read_input_data,read_main_and_secondary_trees,read_port_buffer_uchar,'+
    'read_port_buffer_ulong,read_port_buffer_ushort,read_port_uchar,read_port_ulong,'+
    'read_port_ushort,read_register_buffer_uchar,read_register_buffer_ulong,'+
    'read_register_buffer_ushort,read_register_uchar,read_register_ulong,'+
    'read_register_ushort,readblobfromfile,readcabinetstate,readcfdataentry,'+
    'readcffileentry,readclassstg,readclassstm,readconsole,readconsolea,'+
    'readconsoleinput,readconsoleinputa,readconsoleinputex,readconsoleinputexa,'+
    'readconsoleinputexw,readconsoleinputw,readconsoleoutput,readconsoleoutputa,'+
    'readconsoleoutputattribute,readconsoleoutputcharacter,'+
    'readconsoleoutputcharactera,readconsoleoutputcharacterw,readconsoleoutputw,'+
    'readconsolew,readdir,readdirectorychanges,readdirectorychangesw,'+
    'readencryptedfileraw,readeventlog,readeventloga,readeventlogw,readfile,'+
    'readfileex,readfilescatter,readfmtusertypestg,readglobalpwrpolicy,readline,'+
    'readolestg,readport,readprinter,readprocessmemory,readprocessorpwrscheme,'+
    'readpsz,readpwrscheme,readreptree,readstringstream,readurlcacheentrystream,'+
    'realchildwindowfrompoint,realdrivetype,realgetwindowclass,realgetwindowclassa,'+
    'realgetwindowclassw,realizepalette,realloc,reallocadsmem,reallocadsstr,'+
    'reallocmemory,reallocsplmem,reallocsplstr,realshellexecute,realshellexecutea,'+
    'realshellexecuteex,realshellexecuteexa,realshellexecuteexw,realshellexecutew,'+
    'rebarbandinfo,rebaseimage,rebaseimage64,rebootcheckoninstall,'+
    'recovery_agent_information,rectangle,rectinregion,rectvisible,'+
    'recursivedeletekey,recv,recvfrom,recyclesurrogate,redefcall_new,'+
    'redefcall_release,redefoncommand,redo_first_block,redrawwindow,refcntloaddriver,'+
    'refcntunloaddriver,refreshconnections,refreshpolicy,refreshpolicyex,'+
    'reg_readglobalsex,regclosekey,regconnectregistry,regconnectregistrya,'+
    'regconnectregistryw,regcreateblobkey,regcreatekey,regcreatekeya,regcreatekeyex,'+
    'regcreatekeyexa,regcreatekeyexw,regcreatekeyw,regdeletekey,regdeletekeya,'+
    'regdeletekeyw,regdeletevalue,regdeletevaluea,regdeletevaluew,'+
    'regdisablepredefinedcache,regenerateuserenvironment,regenumkey,regenumkeya,'+
    'regenumkeyex,regenumkeyexa,regenumkeyexw,regenumkeyw,regenumvalue,regenumvaluea,'+
    'regenumvaluew,regflushkey,reggethandlerregistrationinfo,'+
    'reggethandlertoplevelkey,reggetkeysecurity,reggetprogressdetailsstate,'+
    'reggetschedconnectionname,reggetschedsyncsettings,reggetsyncitemsettings,'+
    'reggetsyncsettings,reginstall,register_icmp,registeractiveobject,'+
    'registeranimator,registerbindstatuscallback,registerclass,registerclassa,'+
    'registerclassex,registerclassexa,registerclassexw,registerclassname,'+
    'registerclassnamew,registerclassw,registerclipboardformat,'+
    'registerclipboardformata,registerclipboardformatw,registerclusternotify,'+
    'registercmm,registercmma,registercmmw,registerconsoleime,registerconsoleos2,'+
    'registerconsolevdm,registerdebugout,registerdevicenotification,'+
    'registerdevicenotificationa,registerdevicenotificationw,registerdragdrop,'+
    'registereventsource,registereventsourcea,registereventsourcew,'+
    'registerformatenumerator,registergpnotification,registerhotkey,registeridletask,'+
    'registermediatypeclass,registermediatypes,registernotification,registerocx,'+
    'registeropregionhandler,registerrawinputdevices,registerservice,'+
    'registerservicectrlhandler,registerservicectrlhandlera,'+
    'registerservicectrlhandlerex,registerservicectrlhandlerexa,'+
    'registerservicectrlhandlerexw,registerservicectrlhandlerw,'+
    'registershellhookwindow,registertraceguids,registertraceguidsa,'+
    'registertraceguidsw,registertypelib,registertypelibforuser,'+
    'registerurlcachenotification,registerwaiteventbinding,registerwaiteventstimers,'+
    'registerwaitforinputidle,registerwaitforsingleobject,'+
    'registerwaitforsingleobjectex,registerwindowmessage,registerwindowmessagea,'+
    'registerwindowmessagew,registerwowbasehandlers,registerwowexec,registerwowidle,'+
    'regloadkey,regloadkeya,regloadkeyw,regnotifychangekeyvalue,regopenblobkey,'+
    'regopencurrentuser,regopenkey,regopenkeya,regopenkeyex,regopenkeyexa,'+
    'regopenkeyexw,regopenkeyw,regopenuserclassesroot,regoverridepredefkey,'+
    'regqueryinfokey,regqueryinfokeya,regqueryinfokeyw,regqueryloadhandleronevent,'+
    'regquerymultiplevalues,regquerymultiplevaluesa,regquerymultiplevaluesw,'+
    'regqueryvalue,regqueryvaluea,regqueryvalueex,regqueryvalueexa,regqueryvalueexw,'+
    'regqueryvaluew,regremovemanualsyncsettings,regreplacekey,regreplacekeya,'+
    'regreplacekeyw,regrestoreall,regrestorekey,regrestorekeya,regrestorekeyw,'+
    'regsavekey,regsavekeya,regsavekeyex,regsavekeyexa,regsavekeyexw,regsavekeyw,'+
    'regsaverestore,regsaverestoreoninf,regschedhandleritemschecked,'+
    'regsetkeysecurity,regsetprogressdetailsstate,regsetsyncitemsettings,'+
    'regsetuserdefaults,regsetvalue,regsetvaluea,regsetvalueex,regsetvalueexa,'+
    'regsetvalueexw,regsetvaluew,regstiforwia,regunloadkey,regunloadkeya,'+
    'regunloadkeyw,reint_wndproc,releaseactctx,releaseappcategoryinfolist,'+
    'releasebindinfo,releasecapture,releasedc,releaseeventsystem,releaseframe,'+
    'releaseinterface,releasemutex,releasentmscleanerslot,releasepackagedetail,'+
    'releasepackageinfo,releasesemaphore,releasestgmedium,remote_name_info,'+
    'remoteassistancepreparesystemrestore,remotefindfirstprinterchangenotification,'+
    'remove,remove_symbol,removeclusterresourcedependency,removeclusterresourcenode,'+
    'removedirectory,removedirectorya,removedirectoryw,removefontmemresourceex,'+
    'removefontresource,removefontresourcea,removefontresourceex,'+
    'removefontresourceexa,removefontresourceexw,removefontresourcew,removefromblob,'+
    'removehook,removelocalalternatecomputername,removelocalalternatecomputernamea,'+
    'removelocalalternatecomputernamew,removemenu,removeprop,removepropa,removepropw,'+
    'removetracecallback,removeusersfromencryptedfile,removevectoredexceptionhandler,'+
    'removewindowsubclass,rename,repairstartmenuitems,replacefile,replacefilea,'+
    'replacefilew,replacetext,replacetexta,replacetextw,replycloseprinter,'+
    'replymessage,replyopenprinter,replyprinterchangenotification,reporterror,'+
    'reportevent,reporteventa,reporteventw,requestdevicewakeup,requestwakeuplatency,'+
    'reserventmscleanerslot,reset_decoder_trees,reset_translation,resetdc,resetdca,'+
    'resetdcw,resetevent,resetprinter,resetprintera,resetprinterw,'+
    'resetpropertyinstancelength,resetsr,resetuserspecialfolderpaths,resetwritewatch,'+
    'resizepalette,restartdialog,restartdialogex,restartlinklayermulticast,'+
    'restoreclusterdatabase,restoredc,restorelasterror,restoremediasense,'+
    'restoreperfregistryfromfile,restoreperfregistryfromfilew,restoresnapshot,'+
    'resumeclusternode,resumesuspendeddownload,resumethread,resumetimerthread,'+
    'resutiladdunknownproperties,resutilcreatedirectorytree,resutildupparameterblock,'+
    'resutildupstring,resutilenumprivateproperties,resutilenumproperties,'+
    'resutilenumresources,resutilenumresourcesex,resutilexpandenvironmentstrings,'+
    'resutilfindbinaryproperty,resutilfinddependentdiskresourcedriveletter,'+
    'resutilfinddwordproperty,resutilfindexpandedszproperty,'+
    'resutilfindexpandszproperty,resutilfindlongproperty,resutilfindmultiszproperty,'+
    'resutilfindszproperty,resutilfreeenvironment,resutilfreeparameterblock,'+
    'resutilgetallproperties,resutilgetbinaryproperty,resutilgetbinaryvalue,'+
    'resutilgetcoreclusterresources,resutilgetdwordproperty,resutilgetdwordvalue,'+
    'resutilgetenvironmentwithnetname,resutilgetmultiszproperty,'+
    'resutilgetprivateproperties,resutilgetproperties,'+
    'resutilgetpropertiestoparameterblock,resutilgetproperty,'+
    'resutilgetpropertyformats,resutilgetpropertysize,resutilgetresourcedependency,'+
    'resutilgetresourcedependencybyclass,resutilgetresourcedependencybyname,'+
    'resutilgetresourcedependentipaddressprops,resutilgetresourcename,'+
    'resutilgetresourcenamedependency,resutilgetszproperty,resutilgetszvalue,'+
    'resutilispathvalid,resutilisresourceclassequal,'+
    'resutilpropertylistfromparameterblock,resutilresourcesequal,'+
    'resutilresourcetypesequal,resutilsetbinaryvalue,resutilsetdwordvalue,'+
    'resutilsetexpandszvalue,resutilsetmultiszvalue,resutilsetprivatepropertylist,'+
    'resutilsetpropertyparameterblock,resutilsetpropertyparameterblockex,'+
    'resutilsetpropertytable,resutilsetpropertytableex,'+
    'resutilsetresourceserviceenvironment,resutilsetresourceservicestartparameters,'+
    'resutilsetszvalue,resutilsetunknownproperties,resutilstartresourceservice,'+
    'resutilstopresourceservice,resutilstopservice,'+
    'resutilterminateserviceprocessfromresdll,resutilverifyprivatepropertylist,'+
    'resutilverifypropertytable,resutilverifyresourceservice,resutilverifyservice,'+
    'retfonthandle,retrievepkcs7fromca,retrieveurlcacheentryfile,'+
    'retrieveurlcacheentryfilea,retrieveurlcacheentryfilew,'+
    'retrieveurlcacheentrystream,retrieveurlcacheentrystreama,'+
    'retrieveurlcacheentrystreamw,return_difference,reuseddelparam,'+
    'revertsecuritycontext,reverttoprinterself,reverttoself,revokeactiveobject,'+
    'revokebindstatuscallback,revokedragdrop,revokeformatenumerator,rewinddir,rexec,'+
    'riched1,riched2,rmdir,rmvb,rmvq,roldata,rollbackdriver,rordata,rotateright,'+
    'roundrect,routerallocbidimem,routerallocbidiresponsecontainer,'+
    'routerallocprinternotifyinfo,routerassert,routerentrydlg,routerentrydlga,'+
    'routerentrydlgw,routerfindfirstprinterchangenotification,'+
    'routerfindnextprinterchangenotification,routerfreebidimem,'+
    'routerfreebidiresponsecontainer,routerfreeprinternotifyinfo,'+
    'routergeterrorstring,routergeterrorstringa,routergeterrorstringw,'+
    'routerlogderegister,routerlogderegistera,routerlogderegisterw,routerlogevent,'+
    'routerlogeventa,routerlogeventdata,routerlogeventdataa,routerlogeventdataw,'+
    'routerlogeventex,routerlogeventexa,routerlogeventexw,routerlogeventstring,'+
    'routerlogeventstringa,routerlogeventstringw,routerlogeventvalistex,'+
    'routerlogeventvalistexa,routerlogeventvalistexw,routerlogeventw,'+
    'routerlogregister,routerlogregistera,routerlogregisterw,'+
    'routerrefreshprinterchangenotification,routerreplyprinter,rpcabortasynccall,'+
    'rpcasyncabortcall,rpcasynccancelcall,rpcasynccompletecall,rpcasyncgetcallstatus,'+
    'rpcasyncinitializehandle,rpcasyncregisterinfo,rpcbindingcopy,rpcbindingfree,'+
    'rpcbindingfromstringbinding,rpcbindingfromstringbindinga,'+
    'rpcbindingfromstringbindingw,rpcbindinginqauthclient,rpcbindinginqauthclienta,'+
    'rpcbindinginqauthclientex,rpcbindinginqauthclientexa,rpcbindinginqauthclientexw,'+
    'rpcbindinginqauthclientw,rpcbindinginqauthinfo,rpcbindinginqauthinfoa,'+
    'rpcbindinginqauthinfoex,rpcbindinginqauthinfoexa,rpcbindinginqauthinfoexw,'+
    'rpcbindinginqauthinfow,rpcbindinginqobject,rpcbindinginqoption,rpcbindingreset,'+
    'rpcbindingserverfromclient,rpcbindingsetauthinfo,rpcbindingsetauthinfoa,'+
    'rpcbindingsetauthinfoex,rpcbindingsetauthinfoexa,rpcbindingsetauthinfoexw,'+
    'rpcbindingsetauthinfow,rpcbindingsetobject,rpcbindingsetoption,'+
    'rpcbindingtostringbinding,rpcbindingtostringbindinga,rpcbindingtostringbindingw,'+
    'rpcbindingvectorfree,rpccancelasynccall,rpccancelthread,rpccancelthreadex,'+
    'rpccertgenerateprincipalname,rpccertgenerateprincipalnamea,'+
    'rpccertgenerateprincipalnamew,rpccompleteasynccall,rpcepregister,rpcepregistera,'+
    'rpcepregisternoreplace,rpcepregisternoreplacea,rpcepregisternoreplacew,'+
    'rpcepregisterw,rpcepresolvebinding,rpcepunregister,rpcerroraddrecord,'+
    'rpcerrorclearinformation,rpcerrorendenumeration,rpcerrorgetnextrecord,'+
    'rpcerrorgetnumberofrecords,rpcerrorloaderrorinfo,rpcerrorresetenumeration,'+
    'rpcerrorsaveerrorinfo,rpcerrorstartenumeration,rpcfreeauthorizationcontext,'+
    'rpcgetasynccallstatus,rpcgetauthorizationcontextforclient,rpcheap,'+
    'rpcifidvectorfree,rpcifinqid,rpcimpersonateclient,rpcinitializeasynchandle,'+
    'rpcmgmtenableidlecleanup,rpcmgmtepeltinqbegin,rpcmgmtepeltinqdone,'+
    'rpcmgmtepeltinqnext,rpcmgmtepeltinqnexta,rpcmgmtepeltinqnextw,'+
    'rpcmgmtepunregister,rpcmgmtinqcomtimeout,rpcmgmtinqdefaultprotectlevel,'+
    'rpcmgmtinqifids,rpcmgmtinqserverprincname,rpcmgmtinqserverprincnamea,'+
    'rpcmgmtinqserverprincnamew,rpcmgmtinqstats,rpcmgmtisserverlistening,'+
    'rpcmgmtsetauthorizationfn,rpcmgmtsetcanceltimeout,rpcmgmtsetcomtimeout,'+
    'rpcmgmtsetserverstacksize,rpcmgmtstatsvectorfree,rpcmgmtstopserverlistening,'+
    'rpcmgmtwaitserverlisten,rpcmsg,rpcnetworkinqprotseqs,rpcnetworkinqprotseqsa,'+
    'rpcnetworkinqprotseqsw,rpcnetworkisprotseqvalid,rpcnetworkisprotseqvalida,'+
    'rpcnetworkisprotseqvalidw,rpcnsbindingexport,rpcnsbindingexporta,'+
    'rpcnsbindingexportpnp,rpcnsbindingexportpnpa,rpcnsbindingexportpnpw,'+
    'rpcnsbindingexportw,rpcnsbindingimportbegin,rpcnsbindingimportbegina,'+
    'rpcnsbindingimportbeginw,rpcnsbindingimportdone,rpcnsbindingimportnext,'+
    'rpcnsbindinginqentryname,rpcnsbindinginqentrynamea,rpcnsbindinginqentrynamew,'+
    'rpcnsbindinglookupbegin,rpcnsbindinglookupbegina,rpcnsbindinglookupbeginw,'+
    'rpcnsbindinglookupdone,rpcnsbindinglookupnext,rpcnsbindingselect,'+
    'rpcnsbindingunexport,rpcnsbindingunexporta,rpcnsbindingunexportpnp,'+
    'rpcnsbindingunexportpnpa,rpcnsbindingunexportpnpw,rpcnsbindingunexportw,'+
    'rpcnsentryexpandname,rpcnsentryexpandnamea,rpcnsentryexpandnamew,'+
    'rpcnsentryobjectinqbegin,rpcnsentryobjectinqbegina,rpcnsentryobjectinqbeginw,'+
    'rpcnsentryobjectinqdone,rpcnsentryobjectinqnext,rpcnsgroupdelete,'+
    'rpcnsgroupdeletea,rpcnsgroupdeletew,rpcnsgroupmbradd,rpcnsgroupmbradda,'+
    'rpcnsgroupmbraddw,rpcnsgroupmbrinqbegin,rpcnsgroupmbrinqbegina,'+
    'rpcnsgroupmbrinqbeginw,rpcnsgroupmbrinqdone,rpcnsgroupmbrinqnext,'+
    'rpcnsgroupmbrinqnexta,rpcnsgroupmbrinqnextw,rpcnsgroupmbrremove,'+
    'rpcnsgroupmbrremovea,rpcnsgroupmbrremovew,rpcnsmgmtbindingunexport,'+
    'rpcnsmgmtbindingunexporta,rpcnsmgmtbindingunexportw,rpcnsmgmtentrycreate,'+
    'rpcnsmgmtentrycreatea,rpcnsmgmtentrycreatew,rpcnsmgmtentrydelete,'+
    'rpcnsmgmtentrydeletea,rpcnsmgmtentrydeletew,rpcnsmgmtentryinqifids,'+
    'rpcnsmgmtentryinqifidsa,rpcnsmgmtentryinqifidsw,rpcnsmgmthandlesetexpage,'+
    'rpcnsmgmtinqexpage,rpcnsmgmtsetexpage,rpcnsprofiledelete,rpcnsprofiledeletea,'+
    'rpcnsprofiledeletew,rpcnsprofileeltadd,rpcnsprofileeltadda,rpcnsprofileeltaddw,'+
    'rpcnsprofileeltinqbegin,rpcnsprofileeltinqbegina,rpcnsprofileeltinqbeginw,'+
    'rpcnsprofileeltinqdone,rpcnsprofileeltinqnext,rpcnsprofileeltinqnexta,'+
    'rpcnsprofileeltinqnextw,rpcnsprofileeltremove,rpcnsprofileeltremovea,'+
    'rpcnsprofileeltremovew,rpcobjectinqtype,rpcobjectsetinqfn,rpcobjectsettype,'+
    'rpcprotseqvectorfree,rpcprotseqvectorfreea,rpcprotseqvectorfreew,'+
    'rpcraiseexception,rpcreadstack,rpcregisterasyncinfo,rpcreverttoself,'+
    'rpcreverttoselfex,rpcserverinqbindings,rpcserverinqcallattributes,'+
    'rpcserverinqcallattributesa,rpcserverinqcallattributesw,'+
    'rpcserverinqdefaultprincname,rpcserverinqdefaultprincnamea,'+
    'rpcserverinqdefaultprincnamew,rpcserverinqif,rpcserverlisten,'+
    'rpcserverregisterauthinfo,rpcserverregisterauthinfoa,rpcserverregisterauthinfow,'+
    'rpcserverregisterif,rpcserverregisterif2,rpcserverregisterifex,'+
    'rpcservertestcancel,rpcserverunregisterif,rpcserverunregisterifex,'+
    'rpcserveruseallprotseqs,rpcserveruseallprotseqsex,rpcserveruseallprotseqsif,'+
    'rpcserveruseallprotseqsifex,rpcserveruseprotseq,rpcserveruseprotseqa,'+
    'rpcserveruseprotseqep,rpcserveruseprotseqepa,rpcserveruseprotseqepex,'+
    'rpcserveruseprotseqepexa,rpcserveruseprotseqepexw,rpcserveruseprotseqepw,'+
    'rpcserveruseprotseqex,rpcserveruseprotseqexa,rpcserveruseprotseqexw,'+
    'rpcserveruseprotseqif,rpcserveruseprotseqifa,rpcserveruseprotseqifex,'+
    'rpcserveruseprotseqifexa,rpcserveruseprotseqifexw,rpcserveruseprotseqifw,'+
    'rpcserveruseprotseqw,rpcserveryield,rpcsleep,rpcsmallocate,rpcsmclientfree,'+
    'rpcsmdestroyclientcontext,rpcsmdisableallocate,rpcsmenableallocate,rpcsmfree,'+
    'rpcsmgetthreadhandle,rpcsmsetclientallocfree,rpcsmsetthreadhandle,'+
    'rpcsmswapclientallocfree,rpcssallocate,rpcsscontextlockexclusive,'+
    'rpcsscontextlockshared,rpcssdestroyclientcontext,rpcssdisableallocate,'+
    'rpcssdontserializecontext,rpcssenableallocate,rpcssfree,rpcssgetcontextbinding,'+
    'rpcssgetthreadhandle,rpcsssetclientallocfree,rpcsssetthreadhandle,'+
    'rpcssswapclientallocfree,rpcstringbindingcompose,rpcstringbindingcomposea,'+
    'rpcstringbindingcomposew,rpcstringbindingparse,rpcstringbindingparsea,'+
    'rpcstringbindingparsew,rpcstringfree,rpcstringfreea,rpcstringfreew,rpcsvr,'+
    'rpctestcancel,rpctime,rpcuserfree,rpcverbosestack,rresvport,'+
    'rsopaccesscheckbytype,rsopfileaccesscheck,rsoploggingenabled,'+
    'rsopresetpolicysettingstatus,rsopsetpolicysettingstatus,'+
    'rtcreateinternalcertificate,rtdeleteinternalcert,rtfsync,rtgetinternalcert,'+
    'rtgetusercerts,rtisdependentclient,rtl_free,rtl_malloc,rtlabortrxact,'+
    'rtlabsolutetoselfrelativesd,rtlacquirepeblock,rtlacquireresourceexclusive,'+
    'rtlacquireresourceshared,rtlactivateactivationcontext,'+
    'rtlactivateactivationcontextex,rtlactivateactivationcontextunsafefast,'+
    'rtladdaccessallowedace,rtladdaccessallowedaceex,rtladdaccessallowedobjectace,'+
    'rtladdaccessdeniedace,rtladdaccessdeniedaceex,rtladdaccessdeniedobjectace,'+
    'rtladdace,rtladdactiontorxact,rtladdatomtoatomtable,'+
    'rtladdattributeactiontorxact,rtladdauditaccessace,rtladdauditaccessaceex,'+
    'rtladdauditaccessobjectace,rtladdcompoundace,rtladdrange,'+
    'rtladdrefactivationcontext,rtladdrefmemorystream,rtladdressinsectiontable,'+
    'rtladdvectoredexceptionhandler,rtladjustprivilege,rtlallocateandinitializesid,'+
    'rtlallocatehandle,rtlallocateheap,rtlansichartounicodechar,'+
    'rtlansistringtounicodesize,rtlansistringtounicodestring,rtlappendasciiztostring,'+
    'rtlappendpathelement,rtlappendstringtostring,rtlappendunicodestringtostring,'+
    'rtlappendunicodetostring,rtlapplicationverifierstop,rtlapplyrxact,'+
    'rtlapplyrxactnoflush,rtlareallaccessesgranted,rtlareanyaccessesgranted,'+
    'rtlarebitsclear,rtlarebitsset,rtlassert,rtlassert2,rtlcanceltimer,'+
    'rtlcapturecontext,rtlcapturestackbacktrace,rtlcapturestackcontext,'+
    'rtlchartointeger,rtlcheckfororphanedcriticalsections,rtlcheckprocessparameters,'+
    'rtlcheckregistrykey,rtlclearallbits,rtlclearbit,rtlclearbits,'+
    'rtlclonememorystream,rtlcommitmemorystream,rtlcompactheap,rtlcomparememory,'+
    'rtlcomparememoryulong,rtlcomparestring,rtlcompareunicodestring,'+
    'rtlcompressbuffer,rtlcompresschunks,rtlcomputecrc32,rtlcomputeimporttablehash,'+
    'rtlcomputeprivatizeddllname_u,rtlconsolemultibytetounicoden,'+
    'rtlconvertexclusivetoshared,rtlconvertlongtolargeinteger,'+
    'rtlconvertsharedtoexclusive,rtlconvertsidtounicodestring,'+
    'rtlconverttoautoinheritsecurityobject,rtlconvertuilisttoapilist,'+
    'rtlconvertulongtolargeinteger,rtlcopyluid,rtlcopyluidandattributesarray,'+
    'rtlcopymemory,rtlcopymemorystreamto,rtlcopyoutofprocessmemorystreamto,'+
    'rtlcopyrangelist,rtlcopysecuritydescriptor,rtlcopysid,'+
    'rtlcopysidandattributesarray,rtlcopystring,rtlcopyunicodestring,rtlcreateacl,'+
    'rtlcreateactivationcontext,rtlcreateandsetsd,rtlcreateatomtable,'+
    'rtlcreatebootstatusdatafile,rtlcreateenvironment,rtlcreateheap,'+
    'rtlcreateprocessparameters,rtlcreatequerydebugbuffer,rtlcreateregistrykey,'+
    'rtlcreatesecuritydescriptor,rtlcreatesystemvolumeinformationfolder,'+
    'rtlcreatetagheap,rtlcreatetimer,rtlcreatetimerqueue,rtlcreateunicodestring,'+
    'rtlcreateunicodestringfromasciiz,rtlcreateuserprocess,'+
    'rtlcreateusersecurityobject,rtlcreateuserthread,rtlcustomcptounicoden,'+
    'rtlcutovertimetosystemtime,rtldeactivateactivationcontext,'+
    'rtldeactivateactivationcontextunsafefast,rtldebugprinttimes,rtldecodepointer,'+
    'rtldecodesystempointer,rtldecompressbuffer,rtldecompresschunks,'+
    'rtldecompressfragment,rtldefaultnpacl,rtldelete,rtldeleteace,'+
    'rtldeleteatomfromatomtable,rtldeletecriticalsection,'+
    'rtldeleteelementgenerictable,rtldeleteelementgenerictableavl,rtldeletenosplay,'+
    'rtldeleteownersranges,rtldeleterange,rtldeleteregistryvalue,rtldeleteresource,'+
    'rtldeletesecurityobject,rtldeletetimer,rtldeletetimerqueue,'+
    'rtldeletetimerqueueex,rtldenormalizeprocessparams,rtlderegisterwait,'+
    'rtlderegisterwaitex,rtldescribechunk,rtldestroyatomtable,rtldestroyenvironment,'+
    'rtldestroyhandletable,rtldestroyheap,rtldestroyprocessparameters,'+
    'rtldestroyquerydebugbuffer,rtldeterminedospathnametype_u,'+
    'rtldllshutdowninprogress,rtldnshostnametocomputername,rtldoesfileexists_u,'+
    'rtldosapplyfileisolationredirection_ustr,rtldospathnametontpathname_u,'+
    'rtldossearchpath_u,rtldossearchpath_ustr,rtldowncaseunicodechar,'+
    'rtldowncaseunicodestring,rtldumpresource,rtlduplicateunicodestring,'+
    'rtlemptyatomtable,rtlenableearlycriticalsectioneventcreation,rtlencodepointer,'+
    'rtlencodesystempointer,rtlenlargedintegermultiply,rtlenlargedunsigneddivide,'+
    'rtlenlargedunsignedmultiply,rtlentercriticalsection,rtlenumerategenerictable,'+
    'rtlenumerategenerictableavl,rtlenumerategenerictablelikeadirectory,'+
    'rtlenumerategenerictablewithoutsplaying'+
    'rtlenumerategenerictablewithoutsplayingavl,rtlenumprocessheaps,'+
    'rtlequalcomputername,rtlequaldomainname,rtlequalluid,rtlequalprefixsid,'+
    'rtlequalsid,rtlequalstring,rtlequalunicodestring,rtleraseunicodestring,'+
    'rtlexituserthread,rtlexpandenvironmentstrings_u,rtlextendedintegermultiply,'+
    'rtlextendedlargeintegerdivide,rtlextendedmagicdivide,rtlextendheap,'+
    'rtlfillmemory,rtlfillmemoryulong,rtlfinalreleaseoutofprocessmemorystream,'+
    'rtlfindactivationcontextsectionguid,rtlfindactivationcontextsectionstring,'+
    'rtlfindcharinunicodestring,rtlfindclearbits,rtlfindclearbitsandset,'+
    'rtlfindclearruns,rtlfindfirstrunclear,rtlfindlastbackwardrunclear,'+
    'rtlfindleastsignificantbit,rtlfindlongestrunclear,rtlfindmessage,'+
    'rtlfindmostsignificantbit,rtlfindnextforwardrunclear,rtlfindrange,'+
    'rtlfindsetbits,rtlfindsetbitsandclear,rtlfindunicodeprefix,rtlfirstentryslist,'+
    'rtlfirstfreeace,rtlflushsecurememorycache,rtlformatcurrentuserkeypath,'+
    'rtlformatmessage,rtlfreeansistring,rtlfreehandle,rtlfreeheap,rtlfreeoemstring,'+
    'rtlfreerangelist,rtlfreesid,rtlfreethreadactivationcontextstack,'+
    'rtlfreeunicodestring,rtlfreeuserthreadstack,rtlgenerate8dot3name,rtlgetace,'+
    'rtlgetactiveactivationcontext,rtlgetcallersaddress,'+
    'rtlgetcompressionworkspacesize,rtlgetcontrolsecuritydescriptor,'+
    'rtlgetcurrentdirectory_u,rtlgetcurrentpeb,rtlgetdaclsecuritydescriptor,'+
    'rtlgetdefaultcodepage,rtlgetelementgenerictable,rtlgetelementgenerictableavl,'+
    'rtlgetfirstrange,rtlgetframe,rtlgetfullpathname_u,rtlgetgroupsecuritydescriptor,'+
    'rtlgetlastntstatus,rtlgetlastwin32error,'+
    'rtlgetlengthwithoutlastfulldosorntpathelement'+
    'rtlgetlengthwithouttrailingpathseperators,rtlgetlongestntpathlength,'+
    'rtlgetnativesysteminformation,rtlgetnextrange,rtlgetntglobalflags,'+
    'rtlgetntproducttype,rtlgetntversionnumbers,rtlgetownersecuritydescriptor,'+
    'rtlgetprocessheaps,rtlgetsaclsecuritydescriptor,'+
    'rtlgetsecuritydescriptorrmcontrol,rtlgetsetbootstatusdata,'+
    'rtlgetunloadeventtrace,rtlgetuserinfoheap,rtlgetversion,rtlguidfromstring,'+
    'rtlhashunicodestring,rtlidentifierauthoritysid,rtlimagedirectoryentrytodata,'+
    'rtlimagentheader,rtlimagervatosection,rtlimagervatova,rtlimpersonateself,'+
    'rtlinitansistring,rtlinitansistringex,rtlinitcodepagetable,'+
    'rtlinitializeatompackage,rtlinitializebitmap,rtlinitializecontext,'+
    'rtlinitializecriticalsection,rtlinitializecriticalsectionandspincount,'+
    'rtlinitializegenerictable,rtlinitializegenerictableavl,rtlinitializehandletable,'+
    'rtlinitializerangelist,rtlinitializeresource,rtlinitializerxact,'+
    'rtlinitializesid,rtlinitializeslisthead,rtlinitializestacktracedatabase,'+
    'rtlinitializeunicodeprefix,rtlinitmemorystream,rtlinitnlstables,'+
    'rtlinitoutofprocessmemorystream,rtlinitstring,rtlinitunicodestring,'+
    'rtlinitunicodestringex,rtlinsertelementgenerictable,'+
    'rtlinsertelementgenerictableavl,rtlinsertelementgenerictablefull,'+
    'rtlinsertelementgenerictablefullavl,rtlinsertunicodeprefix,'+
    'rtlint64tounicodestring,rtlintegertochar,rtlintegertounicode,'+
    'rtlintegertounicodestring,rtlinterlockedflushslist,rtlinterlockedpopentryslist,'+
    'rtlinterlockedpushentryslist,rtlinvertrangelist,rtlipv4addresstostring,'+
    'rtlipv4addresstostringa,rtlipv4addresstostringex,rtlipv4addresstostringexa,'+
    'rtlipv4addresstostringexw,rtlipv4addresstostringw,rtlipv4stringtoaddress,'+
    'rtlipv4stringtoaddressa,rtlipv4stringtoaddressex,rtlipv4stringtoaddressexa,'+
    'rtlipv4stringtoaddressexw,rtlipv4stringtoaddressw,rtlipv6addresstostring,'+
    'rtlipv6addresstostringa,rtlipv6addresstostringex,rtlipv6addresstostringexa,'+
    'rtlipv6addresstostringexw,rtlipv6addresstostringw,rtlipv6stringtoaddress,'+
    'rtlipv6stringtoaddressa,rtlipv6stringtoaddressex,rtlipv6stringtoaddressexa,'+
    'rtlipv6stringtoaddressexw,rtlipv6stringtoaddressw,rtlisactivationcontextactive,'+
    'rtlisdosdevicename_u,rtlisgenerictableempty,rtlisgenerictableemptyavl,'+
    'rtlisnamelegaldos8dot3,rtlisrangeavailable,rtlistextunicode,'+
    'rtlisthreadwithinloadercallout,rtlisvalidhandle,rtlisvalidindexhandle,'+
    'rtlisvalidoemcharacter,rtllargeintegeradd,rtllargeintegerarithmeticshift,'+
    'rtllargeintegerdivide,rtllargeintegernegate,rtllargeintegershiftleft,'+
    'rtllargeintegershiftright,rtllargeintegersubtract,rtllargeintegertochar,'+
    'rtlleavecriticalsection,rtllengthrequiredsid,rtllengthsecuritydescriptor,'+
    'rtllengthsid,rtllocaltimetosystemtime,rtllockbootstatusdata,rtllockheap,'+
    'rtllockmemorystreamregion,rtllogstackbacktrace,rtllookupatominatomtable,'+
    'rtllookupelementgenerictable,rtllookupelementgenerictableavl,'+
    'rtllookupelementgenerictablefull,rtllookupelementgenerictablefullavl,'+
    'rtlmakeselfrelativesd,rtlmapgenericmask,rtlmapsecurityerrortontstatus,'+
    'rtlmergerangelists,rtlmovememory,rtlmultiappendunicodestringbuffer,'+
    'rtlmultibytetounicoden,rtlmultibytetounicodesize,rtlnewinstancesecurityobject,'+
    'rtlnewsecuritygrantedaccess,rtlnewsecurityobject,rtlnewsecurityobjectex,'+
    'rtlnewsecurityobjectwithmultipleinheritance,rtlnextunicodeprefix,'+
    'rtlnormalizeprocessparams,rtlntpathnametodospathname,rtlntstatustodoserror,'+
    'rtlntstatustodoserrornoteb,rtlnumbergenerictableelements,'+
    'rtlnumbergenerictableelementsavl,rtlnumberofclearbits,rtlnumberofsetbits,'+
    'rtloemstringtocountedunicodestring,rtloemstringtounicodesize,'+
    'rtloemstringtounicodestring,rtloemtounicoden,rtlopencurrentuser,'+
    'rtlpapplylengthfunction,rtlpctofileheader,rtlpensurebuffersize,'+
    'rtlpinatominatomtable,rtlpnotownercriticalsection,rtlpntcreatekey,'+
    'rtlpntenumeratesubkey,rtlpntmaketemporarykey,rtlpntopenkey,rtlpntqueryvaluekey,'+
    'rtlpntsetvaluekey,rtlpopframe,rtlprefixstring,rtlprefixunicodestring,'+
    'rtlprotectheap,rtlpunwaitcriticalsection,rtlpushframe,'+
    'rtlpwaitforcriticalsection,rtlqueryatominatomtable,rtlquerydepthslist,'+
    'rtlqueryenvironmentvariable_u,rtlqueryheapinformation,rtlqueryinformationacl,'+
    'rtlqueryinformationactivationcontext,rtlqueryinformationactiveactivationcontext,'+
    'rtlqueryinterfacememorystream,rtlqueryprocessbacktraceinformation,'+
    'rtlqueryprocessdebuginformation,rtlqueryprocessheapinformation,'+
    'rtlqueryprocesslockinformation,rtlqueryregistryvalues,rtlquerysecurityobject,'+
    'rtlquerytagheap,rtlquerytimezoneinformation,rtlqueueapcwow64thread,'+
    'rtlqueueworkitem,rtlraiseexception,rtlraisestatus,rtlrandom,rtlrandomex,'+
    'rtlreadmemorystream,rtlreadoutofprocessmemorystream,rtlreallocateheap,'+
    'rtlrealpredecessor,rtlrealsuccessor,rtlregistersecurememorycachecallback,'+
    'rtlregisterwait,rtlreleaseactivationcontext,rtlreleasememorystream,'+
    'rtlreleasepeblock,rtlreleaseresource,rtlremotecall,rtlremoveunicodeprefix,'+
    'rtlremovevectoredexceptionhandler,rtlreservechunk,rtlresetrtltranslations,'+
    'rtlrestorelastwin32error,rtlrevertmemorystream,rtlrundecodeunicodestring,'+
    'rtlrunencodeunicodestring,rtlsecondssince1970totime,rtlsecondssince1980totime,'+
    'rtlseekmemorystream,rtlselfrelativetoabsolutesd,rtlselfrelativetoabsolutesd2,'+
    'rtlsetallbits,rtlsetattributessecuritydescriptor,rtlsetbit,rtlsetbits,'+
    'rtlsetcontrolsecuritydescriptor,rtlsetcriticalsectionspincount,'+
    'rtlsetcurrentdirectory_u,rtlsetcurrentenvironment,rtlsetdaclsecuritydescriptor,'+
    'rtlsetenvironmentvariable,rtlsetgroupsecuritydescriptor,rtlsetheapinformation,'+
    'rtlsetinformationacl,rtlsetiocompletioncallback,rtlsetlastwin32error,'+
    'rtlsetlastwin32errorandntstatusfromntstatus,rtlsetmemorystreamsize,'+
    'rtlsetownersecuritydescriptor,rtlsetprocessiscritical,'+
    'rtlsetsaclsecuritydescriptor,rtlsetsecuritydescriptorrmcontrol,'+
    'rtlsetsecurityobject,rtlsetsecurityobjectex,rtlsetthreadiscritical,'+
    'rtlsetthreadpoolstartfunc,rtlsettimer,rtlsettimezoneinformation,'+
    'rtlsetunicodecallouts,rtlsetuserflagsheap,rtlsetuservalueheap,rtlsizeheap,'+
    'rtlsplay,rtlstartrxact,rtlstatmemorystream,rtlstringcatexworkera,'+
    'rtlstringcatexworkerw,rtlstringcatnexworkera,rtlstringcatnexworkerw,'+
    'rtlstringcatnworkera,rtlstringcatnworkerw,rtlstringcatworkera,'+
    'rtlstringcatworkerw,rtlstringcbcata,rtlstringcbcatexa,rtlstringcbcatexw,'+
    'rtlstringcbcatna,rtlstringcbcatnexa,rtlstringcbcatnexw,rtlstringcbcatnw,'+
    'rtlstringcbcatw,rtlstringcbcopya,rtlstringcbcopyexa,rtlstringcbcopyexw,'+
    'rtlstringcbcopyna,rtlstringcbcopynexa,rtlstringcbcopynexw,rtlstringcbcopynw,'+
    'rtlstringcbcopyw,rtlstringcblengtha,rtlstringcblengthw,rtlstringcbvprintfa,'+
    'rtlstringcbvprintfexa,rtlstringcbvprintfexw,rtlstringcbvprintfw,'+
    'rtlstringcchcata,rtlstringcchcatexa,rtlstringcchcatexw,rtlstringcchcatna,'+
    'rtlstringcchcatnexa,rtlstringcchcatnexw,rtlstringcchcatnw,rtlstringcchcatw,'+
    'rtlstringcchcopya,rtlstringcchcopyexa,rtlstringcchcopyexw,rtlstringcchcopyna,'+
    'rtlstringcchcopynexa,rtlstringcchcopynexw,rtlstringcchcopynw,rtlstringcchcopyw,'+
    'rtlstringcchlengtha,rtlstringcchlengthw,rtlstringcchvprintfa,'+
    'rtlstringcchvprintfexa,rtlstringcchvprintfexw,rtlstringcchvprintfw,'+
    'rtlstringcopyexworkera,rtlstringcopyexworkerw,rtlstringcopynexworkera,'+
    'rtlstringcopynexworkerw,rtlstringcopynworkera,rtlstringcopynworkerw,'+
    'rtlstringcopyworkera,rtlstringcopyworkerw,rtlstringfromguid,'+
    'rtlstringlengthworkera,rtlstringlengthworkerw,rtlstringvprintfexworkera,'+
    'rtlstringvprintfexworkerw,rtlstringvprintfworkera,rtlstringvprintfworkerw,'+
    'rtlsubauthoritycountsid,rtlsubauthoritysid,rtlsubtreepredecessor,'+
    'rtlsubtreesuccessor,rtlsystemtimetolocaltime,rtltestbit,rtltimefieldstotime,'+
    'rtltimetoelapsedtimefields,rtltimetosecondssince1970,rtltimetosecondssince1980,'+
    'rtltimetotimefields,rtltracedatabaseadd,rtltracedatabasecreate,'+
    'rtltracedatabasedestroy,rtltracedatabaseenumerate,rtltracedatabasefind,'+
    'rtltracedatabaselock,rtltracedatabaseunlock,rtltracedatabasevalidate,'+
    'rtltryentercriticalsection,rtlunhandledexceptionfilter,'+
    'rtlunhandledexceptionfilter2,rtlunicodestringcopyexworker,'+
    'rtlunicodestringcopystringexworker,rtlunicodestringcopystringnexworker,'+
    'rtlunicodestringcopystringnworker,rtlunicodestringcopystringworker,'+
    'rtlunicodestringcopyworker,rtlunicodestringexhandlefailureworker,'+
    'rtlunicodestringinitworker,rtlunicodestringlengthhelper,'+
    'rtlunicodestringtoansisize,rtlunicodestringtoansistring,'+
    'rtlunicodestringtocountedoemstring,rtlunicodestringtointeger,'+
    'rtlunicodestringtooemsize,rtlunicodestringtooemstring,'+
    'rtlunicodestringvalidatedestworker,rtlunicodestringvalidatesrcworker,'+
    'rtlunicodestringvalidateworker,rtlunicodestringvprintfexworker,'+
    'rtlunicodestringvprintfworker,rtlunicodetocustomcpn,rtlunicodetomultibyten,'+
    'rtlunicodetomultibytesize,rtlunicodetooemn,rtluniform,rtlunlockbootstatusdata,'+
    'rtlunlockheap,rtlunlockmemorystreamregion,rtlunwind,rtlupcaseunicodechar,'+
    'rtlupcaseunicodestring,rtlupcaseunicodestringtoansistring,'+
    'rtlupcaseunicodestringtocountedoemstring,rtlupcaseunicodestringtooemstring,'+
    'rtlupcaseunicodetocustomcpn,rtlupcaseunicodetomultibyten,rtlupcaseunicodetooemn,'+
    'rtlupdatetimer,rtlupperchar,rtlupperstring,rtlusageheap,rtlvalidacl,'+
    'rtlvalidateheap,rtlvalidateprocessheaps,rtlvalidateunicodestring,'+
    'rtlvalidrelativesecuritydescriptor,rtlvalidsecuritydescriptor,rtlvalidsid,'+
    'rtlverifyversioninfo,rtlvolumedevicetodosname,rtlwalkframechain,rtlwalkheap,'+
    'rtlwritememorystream,rtlwriteregistryvalue,rtlxansistringtounicodesize,'+
    'rtlxoemstringtounicodesize,rtlxunicodestringtoansisize,'+
    'rtlxunicodestringtooemsize,rtlzeroheap,rtlzeromemory,'+
    'rtlzombifyactivationcontext,rtmaddnexthop,rtmaddroute,rtmaddroutetodest,'+
    'rtmblockconvertroutestostatic,rtmblockdeleteroutes,rtmblockmethods,'+
    'rtmblocksetrouteenable,rtmcloseenumerationhandle,rtmcreatedestenum,'+
    'rtmcreateenumerationhandle,rtmcreatenexthopenum,rtmcreaterouteenum,'+
    'rtmcreateroutelist,rtmcreateroutelistenum,rtmcreateroutetable,'+
    'rtmdeleteenumhandle,rtmdeletenexthop,rtmdeleteroute,rtmdeleteroutelist,'+
    'rtmdeleteroutetable,rtmdeleteroutetodest,rtmdequeueroutechangemessage,'+
    'rtmderegisterclient,rtmderegisterentity,rtmderegisterfromchangenotification,'+
    'rtmenumerategetnextroute,rtmfindnexthop,rtmgetaddressfamilyinfo,'+
    'rtmgetchangeddests,rtmgetchangestatus,rtmgetdestinfo,rtmgetentityinfo,'+
    'rtmgetentitymethods,rtmgetenumdests,rtmgetenumnexthops,rtmgetenumroutes,'+
    'rtmgetexactmatchdestination,rtmgetexactmatchroute,rtmgetfirstroute,'+
    'rtmgetinstanceinfo,rtmgetinstances,rtmgetlessspecificdestination,'+
    'rtmgetlistenumroutes,rtmgetmostspecificdestination,rtmgetnetworkcount,'+
    'rtmgetnexthopinfo,rtmgetnexthoppointer,rtmgetnextroute,'+
    'rtmgetopaqueinformationpointer,rtmgetregisteredentities,rtmgetrouteage,'+
    'rtmgetrouteinfo,rtmgetroutepointer,rtmholddestination,rtmignorechangeddests,'+
    'rtminsertinroutelist,rtminvokemethod,rtmisbestroute,'+
    'rtmismarkedforchangenotification,rtmisroute,rtmlockdestination,rtmlocknexthop,'+
    'rtmlockroute,rtmlookupipdestination,rtmmarkdestforchangenotification,'+
    'rtmreadaddressfamilyconfig,rtmreadinstanceconfig,rtmreferencehandles,'+
    'rtmregisterclient,rtmregisterentity,rtmregisterforchangenotification,'+
    'rtmreleasechangeddests,rtmreleasedestinfo,rtmreleasedests,rtmreleaseentities,'+
    'rtmreleaseentityinfo,rtmreleasenexthopinfo,rtmreleasenexthops,'+
    'rtmreleaserouteinfo,rtmreleaseroutes,rtmupdateandunlockroute,'+
    'rtmwriteaddressfamilyconfig,rtmwriteinstanceconfig,rtopeninternalcertstore,'+
    'rtregisterusercert,rtremoveusercert,rtxactgetdtc,run_synch_process_ex,'+
    'rundllregister,runexperts,runoemextratasks,runonceurlcache,runrsopquery,'+
    'runsetupcommand,rxnetaccessadd,rxnetaccessdel,rxnetaccessenum,'+
    'rxnetaccessgetinfo,rxnetaccessgetuserperms,rxnetaccesssetinfo,s_ioctl,s_open,'+
    's_perror,safearrayaccessdata,safearrayallocdata,safearrayallocdescriptor,'+
    'safearrayallocdescriptorex,safearraycopy,safearraycopydata,safearraycreate,'+
    'safearraycreateex,safearraycreatevector,safearraycreatevectorex,'+
    'safearraydestroy,safearraydestroydata,safearraydestroydescriptor,'+
    'safearraygetdim,safearraygetelement,safearraygetelemsize,safearraygetiid,'+
    'safearraygetlbound,safearraygetrecordinfo,safearraygetubound,'+
    'safearraygetvartype,safearraylock,safearrayptrofindex,safearrayputelement,'+
    'safearrayredim,safearraysetiid,safearraysetrecordinfo,safearrayunaccessdata,'+
    'safearrayunlock,safercloselevel,safercomputetokenfromlevel,safercreatelevel,'+
    'safergetlevelinformation,safergetpolicyinformation,saferichangeregistryscope,'+
    'safericomparetokenlevels,saferidentifylevel,saferiisexecutablefiletype,'+
    'saferipopulatedefaultsinregistry,saferirecordeventlogentry,'+
    'saferireplaceprocessthreadtokens,saferisearchmatchinghashrules,'+
    'saferrecordeventlogentry,safersetlevelinformation,safersetpolicyinformation,'+
    'sagetaccountinformation,sagetnsaccountinformation,samaddmembertoalias,'+
    'samaddmembertogroup,samaddmultiplememberstoalias,samchangepassworduser,'+
    'samchangepassworduser2,samchangepassworduser3,samclosehandle,samconnect,'+
    'samconnectwithcreds,samcreatealiasindomain,samcreategroupindomain,'+
    'samcreateuser2indomain,samcreateuserindomain,samdeletealias,samdeletegroup,'+
    'samdeleteuser,samenumeratealiasesindomain,samenumeratedomainsinsamserver,'+
    'samenumerategroupsindomain,samenumerateusersindomain,samestr,samfreememory,'+
    'samgetaliasmembership,samgetcompatibilitymode,samgetdisplayenumerationindex,'+
    'samgetgroupsforuser,samgetmembersinalias,samgetmembersingroup,'+
    'samiaccountrestrictions,samiadddsnametoalias,samiadddsnametogroup,samiamigc,'+
    'samichangekeys,samichangepasswordforeignuser,samichangepasswordforeignuser2,'+
    'samichangepassworduser,samichangepassworduser2,samiconnect,'+
    'samicreateaccountbyrid,samidemote,samidemoteundo,samidofsmorolechange,'+
    'samidscreateobjectindomain,samidssetobjectinformation,samiencryptpasswords,'+
    'samienumerateaccountrids,samienumerateinterdomaintrustaccountsforupgrade,'+
    'samifloatingsinglemasteropex,samifree_sampr_alias_info_buffer,'+
    'samifree_sampr_display_info_buffer,samifree_sampr_domain_info_buffer,'+
    'samifree_sampr_enumeration_buffer,samifree_sampr_get_groups_buffer,'+
    'samifree_sampr_get_members_buffer,samifree_sampr_group_info_buffer,'+
    'samifree_sampr_psid_array,samifree_sampr_returned_ustring_array,'+
    'samifree_sampr_sr_security_descriptor,samifree_sampr_ulong_array,'+
    'samifree_sampr_user_info_buffer,samifree_userinternal6information,'+
    'samifreesidandattributeslist,samifreesidarray,samifreevoid,samigclookupnames,'+
    'samigclookupsids,samigetaliasmembership,samigetbootkeyinformation,'+
    'samigetdefaultadministratorname,samigetfixedattributes,'+
    'samigetinterdomaintrustaccountpasswordsforupgrade,samigetprivatedata,'+
    'samigetresourcegroupmembershipstransitive,samigetserialnumberdomain,'+
    'samigetuserlogoninformation,samigetuserlogoninformation2,'+
    'samigetuserlogoninformationex,samiimpersonatenullsession,'+
    'samiincrementperformancecounter,samiinitialize,samiisdownleveldcupgrade,'+
    'samiisextendedsidmode,samiisrebootafterpromotion,samiissetupinprogress,'+
    'samilmchangepassworduser,samiloaddownleveldatabase,samiloopbackconnect,'+
    'samimixeddomain,samimixeddomain2,saminetlogonping,saminotifydelta,'+
    'saminotifyrolechange,saminotifyserverdelta,samint4upgradeinprogress,'+
    'samioemchangepassworduser2,samiopenaccount,samiopenuserbyalternateid,'+
    'samipromote,samipromoteundo,samiqueryserverrole,samiqueryserverrole2,'+
    'samiremovedsnamefromalias,samiremovedsnamefromgroup,'+
    'samireplacedownleveldatabase,samiresetbadpwdcountonpdc,'+
    'samiretrieveprimarycredentials,samirevertnullsession,samisamesite,'+
    'samisetauditinginformation,samisetbootkeyinformation,samisetdsrmpassword,'+
    'samisetdsrmpasswordowf,samisetmixeddomainflag,samisetpasswordforeignuser,'+
    'samisetpasswordforeignuser2,samisetpasswordinfoonpdc,samisetprivatedata,'+
    'samisetserialnumberdomain,samistoreprimarycredentials,'+
    'samiunloaddownleveldatabase,samiupdatelogonstatistics,samiupnfromuserhandle,'+
    'samlookupdomaininsamserver,samlookupidsindomain,samlookupnamesindomain,'+
    'samopenalias,samopendomain,samopengroup,samopenuser,sampabortsingleloopbacktask,'+
    'sampaccountcontroltoflags,sampacquiresamlockexclusive,sampacquirewritelock,'+
    'sampaddloopbacktask,sampamigc,sampcommitbufferedwrites,sampcomputegrouptype,'+
    'sampconvertnt4sdtont5sd,sampderivemostbasicdsclass,sampdoesdomainexist,'+
    'sampdsattrfromsamattr,sampdschangepassworduser,sampdsclassfromsamobjecttype,'+
    'sampexistsdsloopback,sampexistsdstransaction,sampflagstoaccountcontrol,'+
    'sampgclookupnames,sampgclookupsids,sampgetaccountcounts,sampgetclassattribute,'+
    'sampgetdefaultsecuritydescriptorforclass,sampgetdisplayenumerationindex,'+
    'sampgetdsattridbyname,sampgetenterprisesidlist,sampgetgroupsfortoken,'+
    'sampgetloopbackobjectclassid,sampgetmemberships,sampgetqdirestart,'+
    'sampgetsamattridbyname,sampgetserialnumberdomain2,sampgetserverrolefromfsmo,'+
    'sampinitializeregistry,sampinitializesdconversion,sampinvalidatedomaincache,'+
    'sampinvalidateridrange,sampissecureldapconnection,sampiswritelockheldbyds,'+
    'sampmaybebegindstransaction,sampmaybeenddstransaction,'+
    'sampnetlogonnotificationrequired,sampnetlogonping,sampnotifyreplicatedinchange,'+
    'sampprocesssingleloopbacktask,sampreleasesamlockexclusive,sampreleasewritelock,'+
    'samprtlconvertulongtounicodestring,sampsamattrfromdsattr,'+
    'sampsamobjecttypefromdsclass,sampsetdsa,sampsetindexranges,sampsetlsa,'+
    'sampsetsam,sampsetserialnumberdomain2,sampsignalstart,sampusingdsdata,'+
    'sampverifysids,sampwritegrouptype,samquerydisplayinformation,'+
    'samqueryinformationalias,samqueryinformationdomain,samqueryinformationgroup,'+
    'samqueryinformationuser,samquerysecurityobject,samraddmembertoalias,'+
    'samraddmembertogroup,samraddmultiplememberstoalias,samrchangepassworduser,'+
    'samrclosehandle,samrcreatealiasindomain,samrcreategroupindomain,'+
    'samrcreateuser2indomain,samrcreateuserindomain,samrdeletealias,samrdeletegroup,'+
    'samrdeleteuser,samremovememberfromalias,samremovememberfromforeigndomain,'+
    'samremovememberfromgroup,samremovemultiplemembersfromalias,'+
    'samrenumeratealiasesindomain,samrenumeratedomainsinsamserver,'+
    'samrenumerategroupsindomain,samrenumerateusersindomain,samrgetaliasmembership,'+
    'samrgetgroupsforuser,samrgetmembersinalias,samrgetmembersingroup,'+
    'samrgetuserdomainpasswordinformation,samridtosid,samrlookupdomaininsamserver,'+
    'samrlookupidsindomain,samrlookupnamesindomain,samropenalias,samropendomain,'+
    'samropengroup,samropenuser,samrquerydisplayinformation,'+
    'samrqueryinformationalias,samrqueryinformationdomain,samrqueryinformationgroup,'+
    'samrqueryinformationuser,samrquerysecurityobject,samrremovememberfromalias,'+
    'samrremovememberfromforeigndomain,samrremovememberfromgroup,'+
    'samrremovemultiplemembersfromalias,samrridtosid,samrsetinformationalias,'+
    'samrsetinformationdomain,samrsetinformationgroup,samrsetinformationuser,'+
    'samrsetmemberattributesofgroup,samrsetsecurityobject,samrshutdownsamserver,'+
    'samrtestprivatefunctionsdomain,samrtestprivatefunctionsuser,'+
    'samrunicodechangepassworduser2,samsetinformationalias,samsetinformationdomain,'+
    'samsetinformationgroup,samsetinformationuser,samsetmemberattributesofgroup,'+
    'samsetsecurityobject,samshutdownsamserver,samtestprivatefunctionsdomain,'+
    'samtestprivatefunctionsuser,sasetaccountinformation,sasetnsaccountinformation,'+
    'saslacceptsecuritycontext,saslenumerateprofiles,saslenumerateprofilesa,'+
    'saslenumerateprofilesw,saslgetprofilepackage,saslgetprofilepackagea,'+
    'saslgetprofilepackagew,saslidentifypackage,saslidentifypackagea,'+
    'saslidentifypackagew,saslinitializesecuritycontext,'+
    'saslinitializesecuritycontexta,saslinitializesecuritycontextw,'+
    'satisfyntmsoperatorrequest,savecapture,savecapturew,savedc,savedownlevelcapture,'+
    'saveexpertconfiguration,savefiledialog,savegroup,saveindex,savestate,sb,'+
    'sbmbinsearch,scale,scale2,scaleviewportextex,scalewindowextex,scan,scan_tree,'+
    'scandisplaytext,scantext,scantopictext,scantopictitle,scardaccessstartedevent,'+
    'scardaddreadertogroup,scardaddreadertogroupa,scardaddreadertogroupw,'+
    'scardbegintransaction,scardcancel,scardconnect,scardconnecta,scardconnectw,'+
    'scardcontrol,scarddisconnect,scarddlgextendederror,scardendtransaction,'+
    'scardestablishcontext,scardforgetcardtype,scardforgetcardtypea,'+
    'scardforgetcardtypew,scardforgetreader,scardforgetreadera,'+
    'scardforgetreadergroup,scardforgetreadergroupa,scardforgetreadergroupw,'+
    'scardforgetreaderw,scardfreememory,scardgetattrib,scardgetcardtypeprovidername,'+
    'scardgetcardtypeprovidernamea,scardgetcardtypeprovidernamew,scardgetproviderid,'+
    'scardgetproviderida,scardgetprovideridw,scardgetstatuschange,'+
    'scardgetstatuschangea,scardgetstatuschangew,scardintroducecardtype,'+
    'scardintroducecardtypea,scardintroducecardtypew,scardintroducereader,'+
    'scardintroducereadera,scardintroducereadergroup,scardintroducereadergroupa,'+
    'scardintroducereadergroupw,scardintroducereaderw,scardisvalidcontext,'+
    'scardlistcards,scardlistcardsa,scardlistcardsw,scardlistinterfaces,'+
    'scardlistinterfacesa,scardlistinterfacesw,scardlistreadergroups,'+
    'scardlistreadergroupsa,scardlistreadergroupsw,scardlistreaders,'+
    'scardlistreadersa,scardlistreadersw,scardlocatecards,scardlocatecardsa,'+
    'scardlocatecardsbyatr,scardlocatecardsbyatra,scardlocatecardsbyatrw,'+
    'scardlocatecardsw,scardreconnect,scardreleasecontext,scardreleasestartedevent,'+
    'scardremovereaderfromgroup,scardremovereaderfromgroupa,'+
    'scardremovereaderfromgroupw,scardsetattrib,scardsetcardtypeprovidername,'+
    'scardsetcardtypeprovidernamea,scardsetcardtypeprovidernamew,scardstate,'+
    'scardstatus,scardstatusa,scardstatusw,scardtransmit,scarduidlgselectcard,'+
    'scarduidlgselectcarda,scarduidlgselectcardw,scbinfromhexbounded,'+
    'sccopynotifications,sccopyprops,sccountnotifications,sccountprops,'+
    'sccreateconversationindex,scduppropset,sceaddtonamelist,sceaddtonamestatuslist,'+
    'sceaddtoobjectlist,sceanalyzesystem,sceappendsecurityprofileinfo,'+
    'scebrowsedatabasetable,scecloseprofile,scecommittransaction,scecomparenamelist,'+
    'scecomparesecuritydescriptors,sceconfiguresystem,scecopybaseprofile,'+
    'scecreatedirectory,scedcpromocreategposinsysvol,scedcpromocreategposinsysvolex,'+
    'scedcpromotesecurity,scedcpromotesecurityex,sceenforcesecuritypolicypropagation,'+
    'sceenumerateservices,scefreememory,scefreeprofilememory,scegeneraterollback,'+
    'scegetanalysisareasummary,scegetareas,scegetdatabasesetting,scegetdbtime,'+
    'scegetobjectchildren,scegetobjectsecurity,scegetscpprofiledescription,'+
    'scegetsecurityprofileinfo,scegetserverproducttype,scegettimestamp,'+
    'sceissystemdatabase,scelookupprivrightname,sceopenprofile,sceregisterregvalues,'+
    'scerollbacktransaction,scesetdatabasesetting,scesetupbackupsecurity,'+
    'scesetupconfigureservices,scesetupgeneratetemplate,scesetupmovesecurityfile,'+
    'scesetuprootsecurity,scesetupsystembyinfname,scesetupunwindsecurityfile,'+
    'scesetupupdatesecurityfile,scesetupupdatesecuritykey,'+
    'scesetupupdatesecurityservice,scesrvinitializeserver,scesrvterminateserver,'+
    'scestarttransaction,scesvcconvertsdtotext,scesvcconverttexttosd,scesvcfree,'+
    'scesvcgetinformationtemplate,scesvcqueryinfo,scesvcsetinfo,'+
    'scesvcsetinformationtemplate,scesvcupdateinfo,sceupdateobjectinfo,'+
    'sceupdatesecurityprofile,scewritesecurityprofileinfo,scgeneratemuid,schedulejob,'+
    'scinitmapiutil,sclocalpathfromunc,scmapixfromcmc,scmapixfromsmapi,'+
    'screentoclient,screlocnotifications,screlocprops,scriptapplydigitsubstitution,'+
    'scriptapplylogicalwidth,scriptbreak,scriptcachegetheight,scriptcptox,'+
    'scriptfreecache,scriptgetcmap,scriptgetfontproperties,scriptgetglyphabcwidth,'+
    'scriptgetlogicalwidths,scriptgetproperties,scriptiscomplex,scriptitemize,'+
    'scriptjustify,scriptlayout,scriptplace,scriptrecorddigitsubstitution,'+
    'scriptshape,scriptstring_pcoutchars,scriptstring_plogattr,scriptstring_psize,'+
    'scriptstringanalyse,scriptstringcptox,scriptstringfree,'+
    'scriptstringgetlogicalwidths,scriptstringgetorder,scriptstringout,'+
    'scriptstringvalidate,scriptstringxtocp,scripttextout,scriptxtocp,'+
    'scrollconsolescreenbuffer,scrollconsolescreenbuffera,scrollconsolescreenbufferw,'+
    'scrolldc,scrollwindow,scrollwindowex,scsiclassinstaller,scsidebugprint,'+
    'scsiportcompleterequest,scsiportconvertphysicaladdresstoulong,'+
    'scsiportconvertulongtophysicaladdress,scsiportflushdma,scsiportfreedevicebase,'+
    'scsiportgetbusdata,scsiportgetdevicebase,scsiportgetlogicalunit,'+
    'scsiportgetphysicaladdress,scsiportgetsrb,scsiportgetuncachedextension,'+
    'scsiportgetvirtualaddress,scsiportinitialize,scsiportiomaptransfer,'+
    'scsiportlogerror,scsiportmovememory,scsiportnotification,'+
    'scsiportquerysystemtime,scsiportreadportbufferuchar,scsiportreadportbufferulong,'+
    'scsiportreadportbufferushort,scsiportreadportuchar,scsiportreadportulong,'+
    'scsiportreadportushort,scsiportreadregisterbufferuchar,'+
    'scsiportreadregisterbufferulong,scsiportreadregisterbufferushort,'+
    'scsiportreadregisteruchar,scsiportreadregisterulong,scsiportreadregisterushort,'+
    'scsiportsetbusdatabyoffset,scsiportstallexecution,scsiportvalidaterange,'+
    'scsiportwriteportbufferuchar,scsiportwriteportbufferulong,'+
    'scsiportwriteportbufferushort,scsiportwriteportuchar,scsiportwriteportulong,'+
    'scsiportwriteportushort,scsiportwriteregisterbufferuchar,'+
    'scsiportwriteregisterbufferulong,scsiportwriteregisterbufferushort,'+
    'scsiportwriteregisteruchar,scsiportwriteregisterulong,'+
    'scsiportwriteregisterushort,scsplentry,scuncfromlocalpath,sd,seaccesscheck,'+
    'sealmessage,seappendprivileges,searchintable,searchpath,searchpatha,searchpathw,'+
    'searchstatuscode,searchtreeforfile,seassignsecurity,seassignsecurityex,'+
    'seaudithardlinkcreation,seauditingfileevents,seauditingfileeventswithcontext,'+
    'seauditingfileorglobalevents,seauditinghardlinkevents,'+
    'seauditinghardlinkeventswithcontext,secapturesecuritydescriptor,'+
    'secapturesubjectcontext,secinfo,seclookupaccountname,seclookupaccountsid,'+
    'secloseobjectauditalarm,secmakespn,secmakespnex,second,secreateaccessstate,'+
    'secreateclientsecurity,secreateclientsecurityfromsubjectcontext,'+
    'secsetpagingmode,secureuserprofiles,securitydescriptortobinarysd,'+
    'seddiscretionaryacleditor,sedeassignsecurity,sedeleteaccessstate,'+
    'sedeleteobjectauditalarm,sedsystemacleditor,sedtakeownership,seekfolder,'+
    'seekprinter,seexports,sefiltertoken,sefreeprivileges,seimpersonateclient,'+
    'seimpersonateclientex,select,selectbrushlocal,selectclippath,selectcliprgn,'+
    'selectcmm,selectfontlocal,selectnppblobfromtable,selectobject,selectorlimit,'+
    'selectpalette,selocksubjectcontext,semarklogonsessionforterminationnotification,'+
    'send,send_all_trees,send_bits,send_tree,sendarp,senddatamsg,senddlgitemmessage,'+
    'senddlgitemmessagea,senddlgitemmessagew,senddrivermessage,sendevent,sendicmperr,'+
    'sendimemessageex,sendimemessageexa,sendimemessageexw,sendinput,sendmessage,'+
    'sendmessagea,sendmessagecallback,sendmessagecallbacka,sendmessagecallbackw,'+
    'sendmessagetimeout,sendmessagetimeouta,sendmessagetimeoutw,sendmessagew,'+
    'sendnotifymessage,sendnotifymessagea,sendnotifymessagew,sendrecvbididata,'+
    'sendrenamemsg,sendto,sensnotifynetconevent,sensnotifyrasevent,'+
    'sensnotifywinlogonevent,seopenobjectauditalarm,seopenobjectfordeleteauditalarm,'+
    'seprivilegecheck,seprivilegeobjectauditalarm,sepublicdefaultdacl,'+
    'sequeryauthenticationidtoken,sequeryinformationtoken,'+
    'sequerysecuritydescriptorinfo,sequerysessionidtoken,'+
    'seregisterlogonsessionterminatedroutine,sereleasesecuritydescriptor,'+
    'sereleasesubjectcontext,sereportsecurityevent,serialdisplayadvancedsettings,'+
    'serialkeys,serialportproppageprovider,serverbrowsedialoga0,'+
    'serverdllinitialization,servergetinternetconnectorstatus,serverlicensingclose,'+
    'serverlicensingdeactivatecurrentpolicy,serverlicensingfreepolicyinformation,'+
    'serverlicensinggetavailablepolicyids,serverlicensinggetpolicy,'+
    'serverlicensinggetpolicyinformation,serverlicensinggetpolicyinformationa,'+
    'serverlicensinggetpolicyinformationw,serverlicensingloadpolicy,'+
    'serverlicensingopen,serverlicensingopena,serverlicensingopenw,'+
    'serverlicensingsetpolicy,serverlicensingunloadpolicy,'+
    'serverqueryinetconnectorinformation,serverqueryinetconnectorinformationa,'+
    'serverqueryinetconnectorinformationw,serversetinternetconnectorstatus,'+
    'service_table_entry,serviceinit,servicemain,sesetaccessstategenericmapping,'+
    'sesetauditparameter,sesetsecuritydescriptorinfo,sesetsecuritydescriptorinfoex,'+
    'sesingleprivilegecheck,sesystemdefaultdacl,setabortproc,setaccountsdomainsid,'+
    'setaclinformation,setactivepwrscheme,setactivewindow,setadapteripaddress,'+
    'setaddressdatabaseinstancedata,setaf,setah,setal,setallocfailcount,'+
    'setarcdirection,setattribimsgonistg,setax,setbh,setbitmapbits,'+
    'setbitmapdimensionex,setbkcolor,setbkmode,setbl,setblockroutes,setbmcolor,'+
    'setboolinblob,setboundsrect,setbp,setbrushorgex,setbx,setcalendarinfo,'+
    'setcalendarinfoa,setcalendarinfow,setcapture,setcaptureaddressdb,'+
    'setcaptureinstancedata,setcapturemactype,setcapturetimestamp,setcaretblinktime,'+
    'setcaretpos,setcatalogstate,setccinstptr,setcf,setch,setcl,setclassidinblob,'+
    'setclasslong,setclasslonga,setclasslongw,setclassword,'+
    'setclienttimezoneinformation,setclipboarddata,setclipboardtext,'+
    'setclipboardviewer,setclustergroupname,setclustergroupnodelist,setclustername,'+
    'setclusternetworkname,setclusternetworkpriorityorder,setclusterquorumresource,'+
    'setclusterresourcename,setclusterserviceaccountpassword,setcoloradjustment,'+
    'setcolorprofileelement,setcolorprofileelementreference,'+
    'setcolorprofileelementsize,setcolorprofileheader,setcolorspace,setcommbreak,'+
    'setcommconfig,setcommmask,setcommstate,setcommtimeouts,'+
    'setcompluspackageinstallstatus,setcompressiontype,setcomputername,'+
    'setcomputernamea,setcomputernameex,setcomputernameexa,setcomputernameexw,'+
    'setcomputernamew,setconsoleactivescreenbuffer,setconsolecommandhistorymode,'+
    'setconsolecp,setconsolectrlhandler,setconsolecursor,setconsolecursorinfo,'+
    'setconsolecursormode,setconsolecursorposition,setconsoledisplaymode,'+
    'setconsolefont,setconsolehardwarestate,setconsoleicon,setconsoleinputexename,'+
    'setconsoleinputexenamea,setconsoleinputexenamew,setconsolekeyshortcuts,'+
    'setconsolelocaleudc,setconsolemaximumwindowsize,setconsolemenuclose,'+
    'setconsolemode,setconsolenlsmode,setconsolenumberofcommands,'+
    'setconsolenumberofcommandsa,setconsolenumberofcommandsw,setconsoleos2oemformat,'+
    'setconsoleoutputcp,setconsolepalette,setconsolescreenbuffersize,'+
    'setconsoletextattribute,setconsoletitle,setconsoletitlea,setconsoletitlew,'+
    'setconsolewindowinfo,setcontextattributes,setcontextattributesa,'+
    'setcontextattributesw,setconvertstg,setcpglobal,setcpsuiuserdata,'+
    'setcriticalsectionspincount,setcs,setcurrentdirectory,setcurrentdirectorya,'+
    'setcurrentdirectoryw,setcurrentfilter,setcursor,setcursorpos,setcx,'+
    'setdcbrushcolor,setdcpencolor,setdebugerrorlevel,setdecoder,'+
    'setdecompressiontype,setdefaultcommconfig,setdefaultcommconfiga,'+
    'setdefaultcommconfigw,setdefaultprinter,setdefaultprintera,setdefaultprinterw,'+
    'setdeskwallpaper,setdevicegammaramp,setdf,setdh,setdi,setdibcolortable,'+
    'setdibits,setdibitstodevice,setdirectorylocator,setdl,setdlgitemint,'+
    'setdlgitemtext,setdlgitemtexta,setdlgitemtextw,setdlldirectory,setdlldirectorya,'+
    'setdlldirectoryw,setdocumentbitstg,setdoubleclicktime,setds,setdwordinblob,'+
    'setdx,seteax,setebp,setebx,setecx,setedi,setedx,seteflags,seteip,setendoffile,'+
    'setenhmetafilebits,setentriesinaccesslist,setentriesinaccesslista,'+
    'setentriesinaccesslistw,setentriesinacl,setentriesinacla,setentriesinaclw,'+
    'setentriesinauditlist,setentriesinauditlista,setentriesinauditlistw,'+
    'setenvironmentvariable,setenvironmentvariablea,setenvironmentvariablew,'+
    'seterrorinfo,seterrormode,setes,setesi,setesp,setevent,setfileapistoansi,'+
    'setfileapistooem,setfileattributes,setfileattributesa,setfileattributesw,'+
    'setfilepointer,setfilepointerex,setfilesecurity,setfilesecuritya,'+
    'setfilesecurityw,setfileshortname,setfileshortnamea,setfileshortnamew,'+
    'setfiletime,setfilevaliddata,setfilters,setfirmwareenvironmentvariable,'+
    'setfirmwareenvironmentvariablea,setfirmwareenvironmentvariablew,setfocus,'+
    'setfontenumeration,setforegroundwindow,setform,setforma,setformw,setfs,setgid,'+
    'setgraphicsmode,setgroupname,setgs,sethandlecontext,sethandlecount,'+
    'sethandleinformation,sethostname,seticmmode,seticmprofile,seticmprofilea,'+
    'seticmprofilew,setif,setifentry,setifentrytostack,setimageconfiginformation,'+
    'setimecandidatepos,setinformationcodeauthzlevel,setinformationcodeauthzlevelw,'+
    'setinformationcodeauthzpolicy,setinformationcodeauthzpolicyw,'+
    'setinformationjobobject,setinterfacelinkstatus,setiocompletionproc,setip,'+
    'setipforwardentry,setipforwardentrytostack,setipmultihoprouteentrytostack,'+
    'setipnetentry,setipnetentrytostack,setiprouteentrytostack,setipsecptr,'+
    'setipstatistics,setipstatstostack,setipttl,setjob,setjoba,setjobw,'+
    'setkernelobjectsecurity,setkeyboardstate,setlastconsoleeventactive,setlasterror,'+
    'setlasterrorex,setlayeredwindowattributes,setlayout,setlocale,setlocaleinfo,'+
    'setlocaleinfoa,setlocaleinfow,setlocalprimarycomputername,'+
    'setlocalprimarycomputernamea,setlocalprimarycomputernamew,setlocaltime,'+
    'setmacaddressinblob,setmagiccolors,setmailslotinfo,setmapmode,setmapperflags,'+
    'setmaxamountofprotocols,setmenu,setmenucontexthelpid,setmenudefaultitem,'+
    'setmenuinfo,setmenuitembitmaps,setmenuiteminfo,setmenuiteminfoa,'+
    'setmenuiteminfow,setmessageextrainfo,setmessagequeue,setmessagewaitingindicator,'+
    'setmetafilebitsex,setmetargn,setmiterlimit,setms,setmsw,setnamedpipehandlestate,'+
    'setnamedsecurityinfo,setnamedsecurityinfoa,setnamedsecurityinfoex,'+
    'setnamedsecurityinfoexa,setnamedsecurityinfoexw,setnamedsecurityinfow,'+
    'setnetname,setnetscheduleaccountinformation,setnetworkbuffer,setnetworkcallback,'+
    'setnetworkfilter,setnetworkinfoinblob,setnetworkinstancedata,setnewlookuptables,'+
    'setnextfgpolicyrefreshinfo,setnextnetdrive,setnppaddressfilterinblob,'+
    'setnppetypesapfilter,setnpppatternfilterinblob,setnpptriggerinblob,'+
    'setntmsdevicechangedetection,setntmsmediacomplete,setntmsobjectattribute,'+
    'setntmsobjectattributea,setntmsobjectattributew,setntmsobjectinformation,'+
    'setntmsobjectinformationa,setntmsobjectinformationw,setntmsobjectsecurity,'+
    'setntmsrequestorder,setntmsuioptions,setntmsuioptionsa,setntmsuioptionsw,'+
    'setoanocache,setof,setokenimpersonationlevel,setokenisadmin,setokenisrestricted,'+
    'setokeniswriterestricted,setokenobjecttype,setokentype,setoutputlut,'+
    'setpaletteentries,setparent,setperusersecvalues,setpf,setpgid,setphrasetable,'+
    'setpixel,setpixelformat,setpixelv,setpolyfillmode,setport,setporta,setportw,'+
    'setprinter,setprintera,setprinterdata,setprinterdataa,setprinterdataex,'+
    'setprinterdataexa,setprinterdataexw,setprinterdataw,setprinterw,'+
    'setpriorityclass,setprivateobjectsecurity,setprivateobjectsecurityex,'+
    'setprocessaffinitymask,setprocessdefaultlayout,setprocesspriorityboost,'+
    'setprocessshutdownparameters,setprocesswindowstation,setprocessworkingsetsize,'+
    'setprop,setpropa,setpropw,setproxyarpentrytostack,setreconnectinfo,setrect,'+
    'setrectempty,setrectrgn,setrelabs,setrop2,setroutewithref,setscrollinfo,'+
    'setscrollpos,setscrollrange,setsecuritydescriptorcontrol,'+
    'setsecuritydescriptordacl,setsecuritydescriptorgroup,setsecuritydescriptorowner,'+
    'setsecuritydescriptorrmcontrol,setsecuritydescriptorsacl,setsecurityinfo,'+
    'setsecurityinfoex,setsecurityinfoexa,setsecurityinfoexw,setservice,setservicea,'+
    'setserviceastrusted,setserviceastrusteda,setserviceastrustedw,setservicebits,'+
    'setserviceobjectsecurity,setservicestatus,setservicew,setsf,'+
    'setshadowdescriptorentries,setshellwindow,setsi,setsid,setsockopt,'+
    'setsoftwareupdateadvertisementstate,setsp,setss,setstandardcolorspaceprofile,'+
    'setstandardcolorspaceprofilea,setstandardcolorspaceprofilew,setstdhandle,'+
    'setstretchbltmode,setstringinblob,setsuspendstate,setsyscolors,setsystemcursor,'+
    'setsystempaletteuse,setsystempowerstate,setsystemtime,setsystemtimeadjustment,'+
    'setsysvolsecurityfromdssecurity,settapeparameters,settapeposition,settcpentry,'+
    'settcpentrytostack,settermsrvappinstallmode,settextalign,settextcharacterextra,'+
    'settextcolor,settextjustification,setthemeappproperties,setthreadaffinitymask,'+
    'setthreadcontext,setthreaddesktop,setthreadexecutionstate,'+
    'setthreadidealprocessor,setthreadlocale,setthreadpriority,'+
    'setthreadpriorityboost,setthreadtoken,setthreaduilanguage,settimer,'+
    'settimerqueuetimer,settimezoneinformation,settokeninformation,settracecallback,'+
    'setuid,setunhandledexceptionfilter,setupaddinstallsectiontodiskspacelist,'+
    'setupaddinstallsectiontodiskspacelista,setupaddinstallsectiontodiskspacelistw,'+
    'setupaddorremovetestcertificate,setupaddsectiontodiskspacelist,'+
    'setupaddsectiontodiskspacelista,setupaddsectiontodiskspacelistw,'+
    'setupaddtodiskspacelist,setupaddtodiskspacelista,setupaddtodiskspacelistw,'+
    'setupaddtosourcelist,setupaddtosourcelista,setupaddtosourcelistw,'+
    'setupadjustdiskspacelist,setupadjustdiskspacelista,setupadjustdiskspacelistw,'+
    'setupbackuperror,setupbackuperrora,setupbackuperrorw,setupcache,setupcacheex,'+
    'setupcanceltemporarysourcelist,setupchangefontsize,setupchangelocale,'+
    'setupchangelocaleex,setupclosefilequeue,setupcloseinffile,setupcloselog,'+
    'setupcolormatching,setupcolormatchinga,setupcolormatchingw,setupcomm,'+
    'setupcommitfilequeue,setupcommitfilequeuea,setupcommitfilequeuew,setupcopyerror,'+
    'setupcopyerrora,setupcopyerrorw,setupcopyoeminf,setupcopyoeminfa,'+
    'setupcopyoeminfw,setupcreatediskspacelist,setupcreatediskspacelista,'+
    'setupcreatediskspacelistw,setupcreateoptionalcomponentspage,'+
    'setupdecompressorcopyfile,setupdecompressorcopyfilea,setupdecompressorcopyfilew,'+
    'setupdefaultqueuecallback,setupdefaultqueuecallbacka,setupdefaultqueuecallbackw,'+
    'setupdeleteerror,setupdeleteerrora,setupdeleteerrorw,setupdestroydiskspacelist,'+
    'setupdestroylanguagelist,setupdestroyphonelist,setupdiaskforoemdisk,'+
    'setupdibuildclassinfolist,setupdibuildclassinfolistex,'+
    'setupdibuildclassinfolistexa,setupdibuildclassinfolistexw,'+
    'setupdibuilddriverinfolist,setupdicallclassinstaller,'+
    'setupdicanceldriverinfosearch,setupdichangestate,setupdiclassguidsfromname,'+
    'setupdiclassguidsfromnamea,setupdiclassguidsfromnameex,'+
    'setupdiclassguidsfromnameexa,setupdiclassguidsfromnameexw,'+
    'setupdiclassguidsfromnamew,setupdiclassnamefromguid,setupdiclassnamefromguida,'+
    'setupdiclassnamefromguidex,setupdiclassnamefromguidexa,'+
    'setupdiclassnamefromguidexw,setupdiclassnamefromguidw,setupdicreatedeviceinfo,'+
    'setupdicreatedeviceinfoa,setupdicreatedeviceinfolist,'+
    'setupdicreatedeviceinfolistex,setupdicreatedeviceinfolistexa,'+
    'setupdicreatedeviceinfolistexw,setupdicreatedeviceinfow,'+
    'setupdicreatedeviceinterface,setupdicreatedeviceinterfacea,'+
    'setupdicreatedeviceinterfaceregkey,setupdicreatedeviceinterfaceregkeya,'+
    'setupdicreatedeviceinterfaceregkeyw,setupdicreatedeviceinterfacew,'+
    'setupdicreatedevregkey,setupdicreatedevregkeya,setupdicreatedevregkeyw,'+
    'setupdideletedeviceinfo,setupdideletedeviceinterfacedata,'+
    'setupdideletedeviceinterfaceregkey,setupdideletedevregkey,'+
    'setupdidestroyclassimagelist,setupdidestroydeviceinfolist,'+
    'setupdidestroydriverinfolist,setupdidrawminiicon,setupdienumdeviceinfo,'+
    'setupdienumdeviceinterfaces,setupdienumdriverinfo,setupdienumdriverinfoa,'+
    'setupdienumdriverinfow,setupdigetactualsectiontoinstall,'+
    'setupdigetactualsectiontoinstalla,setupdigetactualsectiontoinstallex,'+
    'setupdigetactualsectiontoinstallexa,setupdigetactualsectiontoinstallexw,'+
    'setupdigetactualsectiontoinstallw,setupdigetclassbitmapindex,'+
    'setupdigetclassdescription,setupdigetclassdescriptiona,'+
    'setupdigetclassdescriptionex,setupdigetclassdescriptionexa,'+
    'setupdigetclassdescriptionexw,setupdigetclassdescriptionw,'+
    'setupdigetclassdevpropertysheets,setupdigetclassdevpropertysheetsa,'+
    'setupdigetclassdevpropertysheetsw,setupdigetclassdevs,setupdigetclassdevsa,'+
    'setupdigetclassdevsex,setupdigetclassdevsexa,setupdigetclassdevsexw,'+
    'setupdigetclassdevsw,setupdigetclassimageindex,setupdigetclassimagelist,'+
    'setupdigetclassimagelistex,setupdigetclassimagelistexa,'+
    'setupdigetclassimagelistexw,setupdigetclassinstallparams,'+
    'setupdigetclassinstallparamsa,setupdigetclassinstallparamsw,'+
    'setupdigetclassregistryproperty,setupdigetclassregistrypropertya,'+
    'setupdigetclassregistrypropertyw,setupdigetcustomdeviceproperty,'+
    'setupdigetcustomdevicepropertya,setupdigetcustomdevicepropertyw,'+
    'setupdigetdeviceinfolistclass,setupdigetdeviceinfolistdetail,'+
    'setupdigetdeviceinfolistdetaila,setupdigetdeviceinfolistdetailw,'+
    'setupdigetdeviceinstallparams,setupdigetdeviceinstallparamsa,'+
    'setupdigetdeviceinstallparamsw,setupdigetdeviceinstanceid,'+
    'setupdigetdeviceinstanceida,setupdigetdeviceinstanceidw,'+
    'setupdigetdeviceinterfacealias,setupdigetdeviceinterfacedetail,'+
    'setupdigetdeviceinterfacedetaila,setupdigetdeviceinterfacedetailw,'+
    'setupdigetdeviceregistryproperty,setupdigetdeviceregistrypropertya,'+
    'setupdigetdeviceregistrypropertyw,setupdigetdriverinfodetail,'+
    'setupdigetdriverinfodetaila,setupdigetdriverinfodetailw,'+
    'setupdigetdriverinstallparams,setupdigetdriverinstallparamsa,'+
    'setupdigetdriverinstallparamsw,setupdigethwprofilefriendlyname,'+
    'setupdigethwprofilefriendlynamea,setupdigethwprofilefriendlynameex,'+
    'setupdigethwprofilefriendlynameexa,setupdigethwprofilefriendlynameexw,'+
    'setupdigethwprofilefriendlynamew,setupdigethwprofilelist,'+
    'setupdigethwprofilelistex,setupdigethwprofilelistexa,setupdigethwprofilelistexw,'+
    'setupdigetinfclass,setupdigetinfclassa,setupdigetinfclassw,'+
    'setupdigetselecteddevice,setupdigetselecteddriver,setupdigetselecteddrivera,'+
    'setupdigetselecteddriverw,setupdigetwizardpage,setupdiinstallclass,'+
    'setupdiinstallclassa,setupdiinstallclassex,setupdiinstallclassexa,'+
    'setupdiinstallclassexw,setupdiinstallclassw,setupdiinstalldevice,'+
    'setupdiinstalldeviceinterfaces,setupdiinstalldriverfiles,setupdiloadclassicon,'+
    'setupdimoveduplicatedevice,setupdiopenclassregkey,setupdiopenclassregkeyex,'+
    'setupdiopenclassregkeyexa,setupdiopenclassregkeyexw,setupdiopendeviceinfo,'+
    'setupdiopendeviceinfoa,setupdiopendeviceinfow,setupdiopendeviceinterface,'+
    'setupdiopendeviceinterfacea,setupdiopendeviceinterfaceregkey,'+
    'setupdiopendeviceinterfacew,setupdiopendevregkey,'+
    'setupdiregistercodeviceinstallers,setupdiregisterdeviceinfo,setupdiremovedevice,'+
    'setupdiremovedeviceinterface,setupdiselectbestcompatdrv,setupdiselectdevice,'+
    'setupdiselectoemdrv,setupdisetclassinstallparams,setupdisetclassinstallparamsa,'+
    'setupdisetclassinstallparamsw,setupdisetclassregistryproperty,'+
    'setupdisetclassregistrypropertya,setupdisetclassregistrypropertyw,'+
    'setupdisetdeviceinstallparams,setupdisetdeviceinstallparamsa,'+
    'setupdisetdeviceinstallparamsw,setupdisetdeviceinterfacedefault,'+
    'setupdisetdeviceregistryproperty,setupdisetdeviceregistrypropertya,'+
    'setupdisetdeviceregistrypropertyw,setupdisetdriverinstallparams,'+
    'setupdisetdriverinstallparamsa,setupdisetdriverinstallparamsw,'+
    'setupdisetselecteddevice,setupdisetselecteddriver,setupdisetselecteddrivera,'+
    'setupdisetselecteddriverw,setupdiunremovedevice,setupduplicatediskspacelist,'+
    'setupduplicatediskspacelista,setupduplicatediskspacelistw,'+
    'setupenumerateregisteredoscomponents,setupenuminfsections,setupenuminfsectionsa,'+
    'setupenuminfsectionsw,setupextendpartition,setupfindfirstline,'+
    'setupfindfirstlinea,setupfindfirstlinew,setupfindnextline,'+
    'setupfindnextmatchline,setupfindnextmatchlinea,setupfindnextmatchlinew,'+
    'setupfreesourcelist,setupfreesourcelista,setupfreesourcelistw,'+
    'setupgetbackupinformation,setupgetbackupinformationa,setupgetbackupinformationw,'+
    'setupgetbinaryfield,setupgetfieldcount,setupgetfilecompressioninfo,'+
    'setupgetfilecompressioninfoa,setupgetfilecompressioninfoex,'+
    'setupgetfilecompressioninfoexa,setupgetfilecompressioninfoexw,'+
    'setupgetfilecompressioninfow,setupgetfilequeuecount,setupgetfilequeueflags,'+
    'setupgetgeooptions,setupgetinffilelist,setupgetinffilelista,'+
    'setupgetinffilelistw,setupgetinfinformation,setupgetinfinformationa,'+
    'setupgetinfinformationw,setupgetinfsections,setupgetintfield,'+
    'setupgetkeyboardoptions,setupgetlinebyindex,setupgetlinebyindexa,'+
    'setupgetlinebyindexw,setupgetlinecount,setupgetlinecounta,setupgetlinecountw,'+
    'setupgetlinetext,setupgetlinetexta,setupgetlinetextw,setupgetlocaleoptions,'+
    'setupgetmultiszfield,setupgetmultiszfielda,setupgetmultiszfieldw,'+
    'setupgetnoninteractivemode,setupgetproducttype,setupgetsetupinfo,'+
    'setupgetsourcefilelocation,setupgetsourcefilelocationa,'+
    'setupgetsourcefilelocationw,setupgetsourcefilesize,setupgetsourcefilesizea,'+
    'setupgetsourcefilesizew,setupgetsourceinfo,setupgetsourceinfoa,'+
    'setupgetsourceinfow,setupgetstringfield,setupgetstringfielda,'+
    'setupgetstringfieldw,setupgettargetpath,setupgettargetpatha,setupgettargetpathw,'+
    'setupgetvalideula,setupinfobjectinstallaction,setupinfobjectinstallactionw,'+
    'setupinitdefaultqueuecallback,setupinitdefaultqueuecallbackex,'+
    'setupinitializefilelog,setupinitializefileloga,setupinitializefilelogw,'+
    'setupinstallcatalog,setupinstallfile,setupinstallfilea,setupinstallfileex,'+
    'setupinstallfileexa,setupinstallfileexw,setupinstallfilesfrominfsection,'+
    'setupinstallfilesfrominfsectiona,setupinstallfilesfrominfsectionw,'+
    'setupinstallfilew,setupinstallfrominfsection,setupinstallfrominfsectiona,'+
    'setupinstallfrominfsectionw,setupinstallservicesfrominfsection,'+
    'setupinstallservicesfrominfsectiona,setupinstallservicesfrominfsectionex,'+
    'setupinstallservicesfrominfsectionexa,setupinstallservicesfrominfsectionexw,'+
    'setupinstallservicesfrominfsectionw,setupiteratecabinet,setupiteratecabineta,'+
    'setupiteratecabinetw,setuplogerror,setuplogerrora,setuplogerrorw,setuplogfile,'+
    'setuplogfilea,setuplogfilew,setupmaptapitoiso,setupnetwork,setupoobebnk,'+
    'setupoobecleanup,setupoobeinitdebuglog,setupoobeinitpostservices,'+
    'setupoobeinitpreservices,setupopenappendinffile,setupopenappendinffilea,'+
    'setupopenappendinffilew,setupopenfilequeue,setupopeninffile,setupopeninffilea,'+
    'setupopeninffilew,setupopenlog,setupopenmasterinf,setuppidgen3,'+
    'setuppreparequeueforrestore,setuppreparequeueforrestorea,'+
    'setuppreparequeueforrestorew,setuppromptfordisk,setuppromptfordiska,'+
    'setuppromptfordiskw,setuppromptreboot,setupquerydrivesindiskspacelist,'+
    'setupquerydrivesindiskspacelista,setupquerydrivesindiskspacelistw,'+
    'setupqueryfilelog,setupqueryfileloga,setupqueryfilelogw,'+
    'setupqueryinffileinformation,setupqueryinffileinformationa,'+
    'setupqueryinffileinformationw,setupqueryinforiginalfileinformation,'+
    'setupqueryinforiginalfileinformationa,setupqueryinforiginalfileinformationw,'+
    'setupqueryinfversioninformation,setupqueryinfversioninformationa,'+
    'setupqueryinfversioninformationw,setupqueryregisteredoscomponent,'+
    'setupqueryregisteredoscomponentsorder,setupquerysourcelist,'+
    'setupquerysourcelista,setupquerysourcelistw,setupqueryspacerequiredondrive,'+
    'setupqueryspacerequiredondrivea,setupqueryspacerequiredondrivew,setupqueuecopy,'+
    'setupqueuecopya,setupqueuecopyindirect,setupqueuecopyindirecta,'+
    'setupqueuecopyindirectw,setupqueuecopysection,setupqueuecopysectiona,'+
    'setupqueuecopysectionw,setupqueuecopyw,setupqueuedefaultcopy,'+
    'setupqueuedefaultcopya,setupqueuedefaultcopyw,setupqueuedelete,'+
    'setupqueuedeletea,setupqueuedeletesection,setupqueuedeletesectiona,'+
    'setupqueuedeletesectionw,setupqueuedeletew,setupqueuerename,setupqueuerenamea,'+
    'setupqueuerenamesection,setupqueuerenamesectiona,setupqueuerenamesectionw,'+
    'setupqueuerenamew,setupreadphonelist,setupregisteroscomponent,'+
    'setupremovefilelogentry,setupremovefilelogentrya,setupremovefilelogentryw,'+
    'setupremovefromdiskspacelist,setupremovefromdiskspacelista,'+
    'setupremovefromdiskspacelistw,setupremovefromsourcelist,'+
    'setupremovefromsourcelista,setupremovefromsourcelistw,'+
    'setupremoveinstallsectionfromdiskspacelist'+
    'setupremoveinstallsectionfromdiskspacelista'+
    'setupremoveinstallsectionfromdiskspacelistw,setupremovesectionfromdiskspacelist,'+
    'setupremovesectionfromdiskspacelista,setupremovesectionfromdiskspacelistw,'+
    'setuprenameerror,setuprenameerrora,setuprenameerrorw,setupscaler,'+
    'setupscanfilequeue,setupscanfilequeuea,setupscanfilequeuew,'+
    'setupsetadminpassword,setupsetdirectoryid,setupsetdirectoryida,'+
    'setupsetdirectoryidex,setupsetdirectoryidexa,setupsetdirectoryidexw,'+
    'setupsetdirectoryidw,setupsetdisplay,setupsetfilequeuealternateplatform,'+
    'setupsetfilequeuealternateplatforma,setupsetfilequeuealternateplatformw,'+
    'setupsetfilequeueflags,setupsetintloptions,setupsetnoninteractivemode,'+
    'setupsetplatformpathoverride,setupsetplatformpathoverridea,'+
    'setupsetplatformpathoverridew,setupsetregisteredoscomponentsorder,'+
    'setupsetsetupinfo,setupsetsourcelist,setupsetsourcelista,setupsetsourcelistw,'+
    'setupshellsettings,setupstartservice,setuptermdefaultqueuecallback,'+
    'setupterminatefilelog,setupuninstallnewlycopiedinfs,setupuninstalloeminf,'+
    'setupuninstalloeminfa,setupuninstalloeminfw,setupunregisteroscomponent,'+
    'setupverifyinffile,setupverifyinffilea,setupverifyinffilew,'+
    'seturlcacheconfiginfo,seturlcacheconfiginfoa,seturlcacheconfiginfow,'+
    'seturlcacheentrygroup,seturlcacheentrygroupa,seturlcacheentrygroupw,'+
    'seturlcacheentryinfo,seturlcacheentryinfoa,seturlcacheentryinfow,'+
    'seturlcachegroupattribute,seturlcachegroupattributea,seturlcachegroupattributew,'+
    'seturlcacheheaderdata,setuserfileencryptionkey,setusergeoid,'+
    'setuserobjectinformation,setuserobjectinformationa,setuserobjectinformationw,'+
    'setuserobjectsecurity,setvarconversionlocalesetting,setvdmcurrentdirectories,'+
    'setviewportextex,setviewportorgex,setvolumelabel,setvolumelabela,'+
    'setvolumelabelw,setvolumemountpoint,setvolumemountpointa,setvolumemountpointw,'+
    'setwaitabletimer,setwin4assertlevel,setwin4infolevel,setwindowcontexthelpid,'+
    'setwindowextex,setwindowlong,setwindowlonga,setwindowlongw,setwindoworgex,'+
    'setwindowplacement,setwindowpos,setwindowrgn,setwindowshook,setwindowshooka,'+
    'setwindowshookex,setwindowshookexa,setwindowshookexw,setwindowshookw,'+
    'setwindowsubclass,setwindowtext,setwindowtexta,setwindowtextw,setwindowtheme,'+
    'setwindowword,setwineventhook,setwinmetafilebits,setworldtransform,setzf,'+
    'seunlocksubjectcontext,seunregisterlogonsessionterminatedroutine,'+
    'sevalidsecuritydescriptor,sfcallback,sfcclose,sfcconnecttoserver,'+
    'sfcfileexception,sfcgetfiles,sfcgetnextprotectedfile,sfcinitiatescan,'+
    'sfcinitprot,sfcinstallprotectedfiles,sfcisfileprotected,'+
    'sfcterminatewatcherthread,sfcwleventlogoff,sfcwleventlogon,sfpdeletecatalog,'+
    'sfpinstallcatalog,sfpverifyfile,shaddfrompropsheetextarray,shaddtorecentdocs,'+
    'shalloc,shallocshared,shappbarmessage,shareasdialoga0,sharecreate,'+
    'sharedaccessresponselisttostring,sharedaccessresponsestringtolist,sharemanage,'+
    'sharestop,shautocomplete,shbindtoparent,shbrowseforfolder,shbrowseforfoldera,'+
    'shbrowseforfolderw,shchangenotification_lock,shchangenotification_unlock,'+
    'shchangenotify,shchangenotifyderegister,shchangenotifyregister,'+
    'shclonespecialidlist,shclsidfromstring,shcocreateinstance,shcopykey,shcopykeya,'+
    'shcopykeyw,shcreatedirectory,shcreatedirectoryex,shcreatedirectoryexa,'+
    'shcreatedirectoryexw,shcreatefileextracticon,shcreatefileextracticonw,'+
    'shcreateprocessasuser,shcreateprocessasuserw,shcreatepropsheetextarray,'+
    'shcreatequerycancelautoplaymoniker,shcreateshellfolderview,'+
    'shcreateshellfolderviewex,shcreateshellitem,shcreateshellpalette,'+
    'shcreatestdenumfmtetc,shcreatestreamonfile,shcreatestreamonfilea,'+
    'shcreatestreamonfileex,shcreatestreamonfilew,shcreatestreamwrapper,'+
    'shcreatethread,shcreatethreadref,shdefextracticon,shdefextracticona,'+
    'shdefextracticonw,shdeleteemptykey,shdeleteemptykeya,shdeleteemptykeyw,'+
    'shdeletekey,shdeletekeya,shdeletekeyw,shdeleteorphankey,shdeleteorphankeya,'+
    'shdeleteorphankeyw,shdeletevalue,shdeletevaluea,shdeletevaluew,'+
    'shdestroypropsheetextarray,shdodragdrop,shechangedir,shechangedira,'+
    'shechangedirex,shechangedirexa,shechangedirexw,shechangedirw,sheconvertpath,'+
    'sheconvertpathw,shefullpath,shefullpatha,shefullpathw,shegetcurdrive,shegetdir,'+
    'shegetdira,shegetdirex,shegetdirexw,shegetdirw,shegetpathoffset,'+
    'shegetpathoffsetw,shell,shell_ex,shell_getcachedimageindex,shell_getimagelists,'+
    'shell_mergemenus,shell_notifyicon,shell_notifyicona,shell_notifyiconw,'+
    'shellabout,shellabouta,shellaboutw,shelldlgproc,shellexecute,shellexecutea,'+
    'shellexecuteex,shellexecuteexa,shellexecuteexw,shellexecuteinfo,shellexecutew,'+
    'shellhookproc,shellmessagebox,shellmessageboxa,shellmessageboxw,'+
    'shemptyrecyclebin,shemptyrecyclebina,shemptyrecyclebinw,'+
    'shenumerateunreadmailaccounts,shenumerateunreadmailaccountsw,shenumkeyex,'+
    'shenumkeyexa,shenumkeyexw,shenumvalue,shenumvaluea,shenumvaluew,sheremovequotes,'+
    'sheremovequotesa,sheremovequotesw,shesetcurdrive,sheshortenpath,sheshortenpatha,'+
    'sheshortenpathw,shextracticons,shextracticonsw,shfileoperation,shfileoperationa,'+
    'shfileoperationw,shfileopstruct,shfind_initmenupopup,shfindfiles,'+
    'shflushclipboard,shflushsfcache,shformatdrive,shfree,shfreenamemappings,'+
    'shfreeshared,shgetattributesfromdataobject,shgetdatafromidlist,'+
    'shgetdatafromidlista,shgetdatafromidlistw,shgetdesktopfolder,'+
    'shgetdiskfreespacea,shgetdiskfreespaceex,shgetdiskfreespaceexa,'+
    'shgetdiskfreespaceexw,shgetfileinfo,shgetfileinfoa,shgetfileinfow,'+
    'shgetfolderlocation,shgetfolderpath,shgetfolderpatha,shgetfolderpathandsubdir,'+
    'shgetfolderpathandsubdira,shgetfolderpathandsubdirw,shgetfolderpathw,'+
    'shgeticonoverlayindex,shgeticonoverlayindexa,shgeticonoverlayindexw,'+
    'shgetimagelist,shgetinstanceexplorer,shgetinversecmap,shgetmalloc,'+
    'shgetnewlinkinfo,shgetnewlinkinfoa,shgetnewlinkinfow,shgetpathfromidlist,'+
    'shgetpathfromidlista,shgetpathfromidlistw,shgetrealidl,'+
    'shgetsetfoldercustomsettings,shgetsetfoldercustomsettingsw,shgetsetsettings,'+
    'shgetsettings,shgetshellstylehinstance,shgetspecialfolderlocation,'+
    'shgetspecialfolderpath,shgetspecialfolderpatha,shgetspecialfolderpathw,'+
    'shgetthreadref,shgetunreadmailcount,shgetunreadmailcountw,shgetvalue,'+
    'shgetvaluea,shgetvaluew,shgetviewstatepropertybag,shhandleupdateimage,'+
    'shilcreatefrompath,shinvokeprintercommand,shinvokeprintercommanda,'+
    'shinvokeprintercommandw,shisfileavailableoffline,shislowmemorymachine,'+
    'shlimitinputedit,shloadindirectstring,shloadinproc,'+
    'shloadnonloadediconoverlayidentifiers,shloadole,shlockshared,'+
    'shmapidlisttoimagelistindexasync,shmappidltosystemimagelistindex,'+
    'shmultifileproperties,shnamemapping,shobjectproperties,'+
    'shopenfolderandselectitems,shopenpropsheet,shopenpropsheetw,shopenregstream,'+
    'shopenregstream2,shopenregstream2a,shopenregstream2w,shopenregstreama,'+
    'shopenregstreamw,showcaret,showcertificate,showclientauthcerts,'+
    'showconsolecursor,showcursor,showdirectoryui,showhidemenuctl,showownedpopups,'+
    'showscrollbar,showsecurityinfo,showwindow,showwindowasync,'+
    'showx509encodedcertificate,shparsedisplayname,shpathprepareforwrite,'+
    'shpathprepareforwritea,shpathprepareforwritew,shpropstgcreate,'+
    'shpropstgreadmultiple,shpropstgwritemultiple,shqueryinfokey,shqueryinfokeya,'+
    'shqueryinfokeyw,shqueryrecyclebin,shqueryrecyclebina,shqueryrecyclebinw,'+
    'shqueryvalueex,shqueryvalueexa,shqueryvalueexw,shregcloseuskey,shregcreateuskey,'+
    'shregcreateuskeya,shregcreateuskeyw,shregdeleteemptyuskey,'+
    'shregdeleteemptyuskeya,shregdeleteemptyuskeyw,shregdeleteusvalue,'+
    'shregdeleteusvaluea,shregdeleteusvaluew,shregduplicatehkey,shregenumuskey,'+
    'shregenumuskeya,shregenumuskeyw,shregenumusvalue,shregenumusvaluea,'+
    'shregenumusvaluew,shreggetboolusvalue,shreggetboolusvaluea,shreggetboolusvaluew,'+
    'shreggetpath,shreggetpatha,shreggetpathw,shreggetusvalue,shreggetusvaluea,'+
    'shreggetusvaluew,shreggetvalue,shreggetvaluea,shreggetvaluew,'+
    'shregistervalidatetemplate,shregopenuskey,shregopenuskeya,shregopenuskeyw,'+
    'shregqueryinfouskey,shregqueryinfouskeya,shregqueryinfouskeyw,shregqueryusvalue,'+
    'shregqueryusvaluea,shregqueryusvaluew,shregsetpath,shregsetpatha,shregsetpathw,'+
    'shregsetusvalue,shregsetusvaluea,shregsetusvaluew,shregwriteusvalue,'+
    'shregwriteusvaluea,shregwriteusvaluew,shreleasethreadref,'+
    'shreplacefrompropsheetextarray,shrestricted,shruncontrolpanel,'+
    'shsetinstanceexplorer,shsetlocalizedname,shsetthreadref,shsetunreadmailcount,'+
    'shsetunreadmailcountw,shsetvalue,shsetvaluea,shsetvaluew,'+
    'shshellfolderview_message,shsimpleidlistfrompath,shskipjunction,'+
    'shstartnetconnectiondialog,shstartnetconnectiondialogw,shstrdup,shstrdupa,'+
    'shstrdupw,shtesttokenmembership,shunlockshared,shupdateimage,shupdateimagea,'+
    'shupdateimagew,shupdaterecyclebinicon,shutdown,shutdowngpoprocessing,'+
    'shutdownias,shvalidateunc,sigaction,sigaddset,sigdelset,sigemptyset,sigfillset,'+
    'sigismember,siglongjmp,signal,signalfileopen,'+
    'signalmachinepolicyforegroundprocessingdone,signalobjectandwait,'+
    'signaluserpolicyforegroundprocessingdone,sigpending,sigprocmask,sigsuspend,'+
    'sim32pgetvdmpointer,simpletypealignment,simpletypebuffersize,'+
    'simpletypememorysize,siscreatebackupstructure,siscreaterestorestructure,'+
    'siscsfilestobackupforlink,sisfreeallocatedmemory,sisfreebackupstructure,'+
    'sisfreerestorestructure,sisrestoredcommonstorefile,sisrestoredlink,'+
    'sizeofresource,sizes,sleep,sleepex,sm,smapls,smapls_ip_ebp_12,smapls_ip_ebp_16,'+
    'smapls_ip_ebp_20,smapls_ip_ebp_24,smapls_ip_ebp_28,smapls_ip_ebp_32,'+
    'smapls_ip_ebp_36,smapls_ip_ebp_40,smapls_ip_ebp_8,smartcardacquireremovelock,'+
    'smartcardacquireremovelockwithtag,smartcardcreatelink,smartcarddevicecontrol,'+
    'smartcardexit,smartcardgetdebuglevel,smartcardinitialize,'+
    'smartcardinitializecardcapabilities,smartcardinvertdata,smartcardlogerror,'+
    'smartcardrawreply,smartcardrawrequest,smartcardreleaseremovelock,'+
    'smartcardreleaseremovelockandwait,smartcardreleaseremovelockwithtag,'+
    'smartcardsetdebuglevel,smartcardt0reply,smartcardt0request,smartcardt1reply,'+
    'smartcardt1request,smartcardupdatecardcapabilities,smd,snb_userfree,'+
    'snb_usermarshal,snb_usersize,snb_userunmarshal,sndplaysound,sndplaysounda,'+
    'sndplaysoundw,sniffstream,snmpcancelmsg,snmpcleanup,snmpclose,snmpcontexttostr,'+
    'snmpconveyagentaddress,snmpcountvbl,snmpcreatepdu,snmpcreatesession,'+
    'snmpcreatevbl,snmpdecodemsg,snmpdeletevb,snmpduplicatepdu,snmpduplicatevbl,'+
    'snmpencodemsg,snmpentitytostr,snmpfreecontext,snmpfreedescriptor,snmpfreeentity,'+
    'snmpfreepdu,snmpfreevbl,snmpgetlasterror,snmpgetpdudata,snmpgetretransmitmode,'+
    'snmpgetretry,snmpgettimeout,snmpgettranslatemode,snmpgetvb,snmpgetvendorinfo,'+
    'snmplisten,snmpmgrclose,snmpmgrctl,snmpmgrgettrap,snmpmgrgettrapex,'+
    'snmpmgroidtostr,snmpmgropen,snmpmgrrequest,snmpmgrstrtooid,snmpmgrtraplisten,'+
    'snmpoidcompare,snmpoidcopy,snmpoidtostr,snmpopen,snmprecvmsg,snmpregister,'+
    'snmpsendmsg,snmpsetagentaddress,snmpsetpdudata,snmpsetport,'+
    'snmpsetretransmitmode,snmpsetretry,snmpsettimeout,snmpsettranslatemode,'+
    'snmpsetvb,snmpstartup,snmpstrtocontext,snmpstrtoentity,snmpstrtooid,'+
    'snmpsvcaddrisipx,snmpsvcaddrtosocket,snmpsvcgetenterpriseoid,snmpsvcgetuptime,'+
    'snmpsvcgetuptimefromtime,snmpsvcinituptime,snmpsvcsetloglevel,snmpsvcsetlogtype,'+
    'snmptfxclose,snmptfxopen,snmptfxquery,snmputilansitounicode,snmputilasnanycpy,'+
    'snmputilasnanyfree,snmputildbgprint,snmputilidstoa,snmputilmemalloc,'+
    'snmputilmemfree,snmputilmemrealloc,snmputiloctetscmp,snmputiloctetscpy,'+
    'snmputiloctetsfree,snmputiloctetsncmp,snmputiloidappend,snmputiloidcmp,'+
    'snmputiloidcpy,snmputiloidfree,snmputiloidncmp,snmputiloidtoa,'+
    'snmputilprintasnany,snmputilprintoid,snmputilunicodetoansi,'+
    'snmputilunicodetoutf8,snmputilutf8tounicode,snmputilvarbindcpy,'+
    'snmputilvarbindfree,snmputilvarbindlistcpy,snmputilvarbindlistfree,socket,'+
    'softpceoi,softpubauthenticode,softpubcheckcert,softpubcleanup,'+
    'softpubdllregisterserver,softpubdllunregisterserver,softpubdumpstructure,'+
    'softpubinitialize,softpubloadmessage,softpubloadsignature,soundsentry,space,'+
    'special_decode_aligned_block,special_decode_verbatim_block,spinit,spinitialize,'+
    'spinstanceinit,splclosespoolfilehandle,splcommitspooldata,'+
    'spldriverunloadcomplete,splgetspoolfileinfo,splinitializewinspooldrv,'+
    'splissessionzero,splisupgrade,split_block,splitsymbols,splpowerevent,'+
    'splprocesspnpevent,splpromptuiinuserssession,splreadprinter,'+
    'splregisterfordeviceevents,splsamodeinitialize,splshutdownrouter,'+
    'splstartphase2init,splunregisterfordeviceevents,spoolercopyfileevent,'+
    'spoolerdevqueryprint,spoolerdevqueryprintw,'+
    'spoolerfindcloseprinterchangenotification'+
    'spoolerfindfirstprinterchangenotification'+
    'spoolerfindnextprinterchangenotification,spoolerfreeprinternotifyinfo,'+
    'spoolerhasinitialized,spoolerinit,spoolerprinterevent,sprintf,'+
    'spusermodeinitialize,sqlallocconnect,sqlallocenv,sqlallochandle,'+
    'sqlallochandlestd,sqlallocstmt,sqlbindcol,sqlbindparam,sqlbindparameter,'+
    'sqlbrowseconnect,sqlbrowseconnecta,sqlbrowseconnectw,sqlbulkoperations,'+
    'sqlcancel,sqlclosecursor,sqlcolattribute,sqlcolattributea,sqlcolattributes,'+
    'sqlcolattributesa,sqlcolattributesw,sqlcolattributew,sqlcolumnprivileges,'+
    'sqlcolumnprivilegesa,sqlcolumnprivilegesw,sqlcolumns,sqlcolumnsa,sqlcolumnsw,'+
    'sqlconnect,sqlconnecta,sqlconnectw,sqlcopydesc,sqldatasources,sqldatasourcesa,'+
    'sqldatasourcesw,sqldescribecol,sqldescribecola,sqldescribecolw,sqldescribeparam,'+
    'sqldisconnect,sqldriverconnect,sqldriverconnecta,sqldriverconnectw,sqldrivers,'+
    'sqldriversa,sqldriversw,sqlendtran,sqlerror,sqlerrora,sqlerrorw,sqlexecdirect,'+
    'sqlexecdirecta,sqlexecdirectw,sqlexecute,sqlextendedfetch,sqlfetch,'+
    'sqlfetchscroll,sqlforeignkeys,sqlforeignkeysa,sqlforeignkeysw,sqlfreeconnect,'+
    'sqlfreeenv,sqlfreehandle,sqlfreestmt,sqlgetconnectattr,sqlgetconnectattra,'+
    'sqlgetconnectattrw,sqlgetconnectoption,sqlgetconnectoptiona,'+
    'sqlgetconnectoptionw,sqlgetcursorname,sqlgetcursornamea,sqlgetcursornamew,'+
    'sqlgetdata,sqlgetdescfield,sqlgetdescfielda,sqlgetdescfieldw,sqlgetdescrec,'+
    'sqlgetdescreca,sqlgetdescrecw,sqlgetdiagfield,sqlgetdiagfielda,sqlgetdiagfieldw,'+
    'sqlgetdiagrec,sqlgetdiagreca,sqlgetdiagrecw,sqlgetenvattr,sqlgetfunctions,'+
    'sqlgetinfo,sqlgetinfoa,sqlgetinfow,sqlgetstmtattr,sqlgetstmtattra,'+
    'sqlgetstmtattrw,sqlgetstmtoption,sqlgettypeinfo,sqlgettypeinfoa,sqlgettypeinfow,'+
    'sqlmoreresults,sqlnativesql,sqlnativesqla,sqlnativesqlw,sqlnumparams,'+
    'sqlnumresultcols,sqlparamdata,sqlparamoptions,sqlprepare,sqlpreparea,'+
    'sqlpreparew,sqlprimarykeys,sqlprimarykeysa,sqlprimarykeysw,sqlprocedurecolumns,'+
    'sqlprocedurecolumnsa,sqlprocedurecolumnsw,sqlprocedures,sqlproceduresa,'+
    'sqlproceduresw,sqlputdata,sqlrowcount,sqlsetconnectattr,sqlsetconnectattra,'+
    'sqlsetconnectattrw,sqlsetconnectoption,sqlsetconnectoptiona,'+
    'sqlsetconnectoptionw,sqlsetcursorname,sqlsetcursornamea,sqlsetcursornamew,'+
    'sqlsetdescfield,sqlsetdescfielda,sqlsetdescfieldw,sqlsetdescrec,sqlsetenvattr,'+
    'sqlsetparam,sqlsetpos,sqlsetscrolloptions,sqlsetstmtattr,sqlsetstmtattra,'+
    'sqlsetstmtattrw,sqlsetstmtoption,sqlspecialcolumns,sqlspecialcolumnsa,'+
    'sqlspecialcolumnsw,sqlstatistics,sqlstatisticsa,sqlstatisticsw,'+
    'sqltableprivileges,sqltableprivilegesa,sqltableprivilegesw,sqltables,sqltablesa,'+
    'sqltablesw,sqltransact,srand,srcompress,srfifo,srfreeze,srnotify,srprintstate,'+
    'srregistersnapshotcallback,srremoverestorepoint,srsetrestorepoint,'+
    'srsetrestorepointa,srsetrestorepointw,srswitchlog,srunregistersnapshotcallback,'+
    'srupdatedssize,srupdatemonitoredlist,srupdatemonitoredlista,'+
    'srupdatemonitoredlistw,srvrwndproc,sscanf,ssdpcleanup,ssdpstartup,'+
    'sslcrackcertificate,sslemptycache,sslemptycachea,sslemptycachew,'+
    'sslfreecertificate,sslgeneratekeypair,sslgeneraterandombits,'+
    'sslgetmaximumkeysize,sslloadcertificate,ssorta,ssortd,'+
    'ssync_ansi_unicode_struct_for_wo,ssync_ansi_unicode_struct_for_wow,stackmatch,'+
    'stackwalk,stackwalk64,startcapturing,startdoc,startdoca,startdocdlg,'+
    'startdocdlga,startdocdlgw,startdocport,startdocprinter,startdocprintera,'+
    'startdocprinterw,startdocw,startformpage,startfwcisvcwork,startpage,'+
    'startpageprinter,startservice,startservicea,startservicectrldispatcher,'+
    'startservicectrldispatchera,startservicectrldispatcherw,startservicew,'+
    'starttrace,starttracea,starttracew,startupinfo,stat,stationquery,stderr,stderrw,'+
    'stdin,stdinw,stdout,stdoutw,stfind,stgconvertpropertytovariant,'+
    'stgconvertvarianttoproperty,stgcreatedocfile,stgcreatedocfileonilockbytes,'+
    'stgcreatepropsetstg,stgcreatepropstg,stgcreatestorageex,'+
    'stggetifilllockbytesonfile,stggetifilllockbytesonilockbytes,stgisstoragefile,'+
    'stgisstorageilockbytes,stgmedium_userfree,stgmedium_usermarshal,'+
    'stgmedium_usersize,stgmedium_userunmarshal,stgopenasyncdocfileonifilllockbytes,'+
    'stgopenlayoutdocfile,stgopenpropstg,stgopenstorage,stgopenstorageex,'+
    'stgopenstorageonilockbytes,stgpropertylengthasvariant,stgsettimes,'+
    'sticreateinstance,sticreateinstancea,sticreateinstancew,stopcapturing,'+
    'stopfwcisvcwork,stopsharedialoga0,stoptrace,stoptracea,stoptracew,'+
    'storagecoinstaller,storportbusy,storportcompleterequest,'+
    'storportconvertulongtophysicaladdress,storportdebugprint,storportdevicebusy,'+
    'storportdeviceready,storportfreedevicebase,storportgetbusdata,'+
    'storportgetdevicebase,storportgetlogicalunit,storportgetphysicaladdress,'+
    'storportgetscattergatherlist,storportgetsrb,storportgetuncachedextension,'+
    'storportgetvirtualaddress,storportinitialize,storportlogerror,'+
    'storportmovememory,storportnotification,storportpause,storportpausedevice,'+
    'storportreadportbufferuchar,storportreadportbufferulong,'+
    'storportreadportbufferushort,storportreadportuchar,storportreadportulong,'+
    'storportreadportushort,storportreadregisterbufferuchar,'+
    'storportreadregisterbufferulong,storportreadregisterbufferushort,'+
    'storportreadregisteruchar,storportreadregisterulong,storportreadregisterushort,'+
    'storportready,storportresume,storportresumedevice,storportsetbusdatabyoffset,'+
    'storportstallexecution,storportsynchronizeaccess,storportvalidaterange,'+
    'storportwriteportbufferuchar,storportwriteportbufferulong,'+
    'storportwriteportbufferushort,storportwriteportuchar,storportwriteportulong,'+
    'storportwriteportushort,storportwriteregisterbufferuchar,'+
    'storportwriteregisterbufferulong,storportwriteregisterbufferushort,'+
    'storportwriteregisteruchar,storportwriteregisterulong,'+
    'storportwriteregisterushort,str_setptr,str_setptrw,strcat,strcatbuff,'+
    'strcatbuffa,strcatbuffw,strcatchain,strcatchainw,strcatw,strchr,strchra,strchri,'+
    'strchria,strchriw,strchrn,strchrni,strchrniw,strchrnw,strchrw,strcmp,strcmpc,'+
    'strcmpca,strcmpcw,strcmpi,strcmpic,strcmpica,strcmpicw,strcmpiw,strcmplogical,'+
    'strcmplogicalw,strcmpn,strcmpna,strcmpni,strcmpnia,strcmpniw,strcmpnw,strcmpw,'+
    'strcpy,strcpy1,strcpyn,strcpynw,strcpyw,strcspn,strcspna,strcspni,strcspnia,'+
    'strcspniw,strcspnw,strdup,strdupa,strdupw,streamclassabortoutstandingrequests,'+
    'streamclasscallatnewpriority,streamclasscompleterequestandmarkqueueready,'+
    'streamclassdebugassert,streamclassdebugprint,streamclassdevicenotification,'+
    'streamclassfilterreenumeratestreams,streamclassgetdmabuffer,'+
    'streamclassgetnextevent,streamclassgetphysicaladdress,streamclasslogerror,'+
    'streamclasspnpadddeviceworker,streamclassquerymasterclock,'+
    'streamclassquerymasterclocksync,streamclassreadwriteconfig,'+
    'streamclassreenumeratestreams,streamclassregisteradapter,'+
    'streamclassregisterfilterwithnokspins,streamclassscheduletimer,stretchblt,'+
    'stretchdib,stretchdibits,strformatbytesize,strformatbytesize64a,'+
    'strformatbytesizea,strformatbytesizew,strformatkbsize,strformatkbsizea,'+
    'strformatkbsizew,strfromtimeinterval,strfromtimeintervala,strfromtimeintervalw,'+
    'stringcatworkera,stringcchcata,stringcchcopya,stringcopyworkera,'+
    'stringdpa_appendstring,stringdpa_appendstringa,stringdpa_appendstringw,'+
    'stringdpa_deletestring,stringdpa_destroy,stringdpa_insertstring,'+
    'stringdpa_insertstringa,stringdpa_insertstringw,stringfromclsid,stringfromguid2,'+
    'stringfromiid,stringfromsearchcolumn,stringlengthworkera,stringtoaddress,'+
    'stringtodatetime,striplf,striprangei,striprangex,strisintlequal,strisintlequala,'+
    'strisintlequalw,strlen,strlog,strmconvertcentisecondstorelativetimeout,'+
    'strmderegisterdriver,strmderegistermodule,strmgeterror,strmgetregvalue,'+
    'strmlogevent,strmopenregkey,strmquerylbolt,strmquerysecondssince1970time,'+
    'strmregisterdriver,strmregistermodule,strmseterror,strmwaitformultipleobjects,'+
    'strmwaitformutexobject,strmwaitforsingleobject,strncat,strncata,strncatw,'+
    'strncmp,strncpy,strobj_benum,strobj_benumpositionsonly,strobj_bgetadvancewidths,'+
    'strobj_dwgetcodepage,strobj_fxbreakextra,strobj_fxcharacterextra,'+
    'strobj_venumstart,strokeandfillpath,strokepath,strpbrk,strpbrka,strpbrkw,'+
    'strqget,strqset,strrchr,strrchra,strrchri,strrchria,strrchriw,strrchrw,'+
    'strrettobstr,strrettobuf,strrettobufa,strrettobufw,strrettostr,strrettostra,'+
    'strrettostrw,strrstri,strrstria,strrstriw,strspn,strspna,strspnw,strstr,strstra,'+
    'strstri,strstria,strstriw,strstrn,strstrni,strstrniw,strstrnw,strstrw,strtoint,'+
    'strtoint64ex,strtoint64exa,strtoint64exw,strtointa,strtointex,strtointexa,'+
    'strtointexw,strtointw,strtok,strtol,strtoul,strtrim,strtrima,strtrimw,stubmsg,'+
    'subkeyexists,submitntmsoperatorrequest,submitntmsoperatorrequesta,'+
    'submitntmsoperatorrequestw,subtractrect,sunmapls,sunmapls_ip_ebp_12,'+
    'sunmapls_ip_ebp_16,sunmapls_ip_ebp_20,sunmapls_ip_ebp_24,sunmapls_ip_ebp_28,'+
    'sunmapls_ip_ebp_32,sunmapls_ip_ebp_36,sunmapls_ip_ebp_40,sunmapls_ip_ebp_8,'+
    'suser,suspendthread,suspendtimerthread,svcentry_cisvc,svchostpushserviceglobals,'+
    'swapbuffers,swapmousebutton,swapntmsmedia,swapplong,swappword,swapuv,'+
    'switchdesktop,switchtofiber,switchtonewcab,switchtothiswindow,switchtothread,'+
    'swprintf,swscanf,symbol,symcleanup,symenumeratemodules,symenumeratemodules64,'+
    'symenumeratesymbols,symenumeratesymbols64,symenumeratesymbolsw,'+
    'symenumeratesymbolsw64,symfunctiontableaccess,symfunctiontableaccess64,'+
    'symgetlinefromaddr,symgetlinefromaddr64,symgetlinefromname,symgetlinefromname64,'+
    'symgetlinenext,symgetlinenext64,symgetlineprev,symgetlineprev64,'+
    'symgetmodulebase,symgetmodulebase64,symgetmoduleinfo,symgetmoduleinfo64,'+
    'symgetmoduleinfoex,symgetmoduleinfoex64,symgetmoduleinfow,symgetmoduleinfow64,'+
    'symgetoptions,symgetsearchpath,symgetsymbolinfo,symgetsymbolinfo64,'+
    'symgetsymfromaddr,symgetsymfromaddr64,symgetsymfromname,symgetsymfromname64,'+
    'symgetsymnext,symgetsymnext64,symgetsymprev,symgetsymprev64,syminitialize,'+
    'symloadmodule,symloadmodule64,symmatchfilename,symregistercallback,'+
    'symregistercallback64,symregisterfunctionentrycallback,'+
    'symregisterfunctionentrycallback64,symsetoptions,symsetsearchpath,symundname,'+
    'symundname64,symunloadmodule,symunloadmodule64,'+
    'synchronizewindows31filesandwindowsntregistry,syncmgrresolveconflict,'+
    'syncmgrresolveconflicta,syncmgrresolveconflictw,sysallocstring,'+
    'sysallocstringbytelen,sysallocstringlen,sysconf,sysfreestring,sysreallocstring,'+
    'sysreallocstringlen,sysstringbytelen,sysstringlen,system,systemfunction001,'+
    'systemfunction002,systemfunction003,systemfunction004,systemfunction005,'+
    'systemfunction006,systemfunction007,systemfunction008,systemfunction009,'+
    'systemfunction010,systemfunction011,systemfunction012,systemfunction013,'+
    'systemfunction014,systemfunction015,systemfunction016,systemfunction017,'+
    'systemfunction018,systemfunction019,systemfunction020,systemfunction021,'+
    'systemfunction022,systemfunction023,systemfunction024,systemfunction025,'+
    'systemfunction026,systemfunction027,systemfunction028,systemfunction029,'+
    'systemfunction030,systemfunction031,systemfunction032,systemfunction033,'+
    'systemfunction034,systemfunction035,systemfunction036,systemfunction040,'+
    'systemfunction041,systemparametersinfo,systemparametersinfoa,'+
    'systemparametersinfow,systemtimetofiletime,systemtimetotzspecificlocaltime,'+
    'systemtimetovarianttime,systemupdateuserprofiledirectory,szappend,szcatstr,'+
    'szcmp,szcmpi,szcopy,szfindch,szfindlastch,szfindsz,szgalign,szgcombine,'+
    'szgcombinech,szgconvtodbcs,szgconvtosbcs,szgcopy,szgcopych,szgfind,szgfindback,'+
    'szgfindbackch,szgfindch,szglower,szgnext,szgprev,szgupper,szleft,szlen,szlower,'+
    'szltrim,szmid,szmonospace,szmulticat,szremove,szrep,szrev,szright,szrtrim,'+
    'sztrim,szupper,szvalign,szvcombine,szvcombinech,szvconvtodbcs,szvconvtosbcs,'+
    'szvcopy,szvcopych,szvdecode,szvencode,szvfind,szvfindback,szvfindbackch,'+
    'szvfindch,szvlower,szvnext,szvprev,szvupper,szwcnt,tabbedtextout,tabbedtextouta,'+
    'tabbedtextoutw,tally_aligned_bits,tally_frequency,tapeclassallocatesrbbuffer,'+
    'tapeclasscomparememory,tapeclassinitialize,tapeclassinstaller,tapeclasslidiv,'+
    'tapeclasslogicalblocktophysicalblock,tapeclassphysicalblocktologicalblock,'+
    'tapeclasszeromemory,tapeproppageprovider,tapiclient_clientinitialize,'+
    'tapiclient_clientshutdown,tapiclient_free,tapiclient_getdeviceaccess,'+
    'tapiclient_lineaddtoconference,tapiclient_lineblindtransfer,'+
    'tapiclient_lineconfigdialog,tapiclient_linedial,tapiclient_lineforward,'+
    'tapiclient_linegeneratedigits,tapiclient_linemakecall,tapiclient_lineopen,'+
    'tapiclient_lineredirect,tapiclient_linesetcalldata,tapiclient_linesetcallparams,'+
    'tapiclient_linesetcallprivilege,tapiclient_linesetcalltreatment,'+
    'tapiclient_linesetcurrentlocation,tapiclient_linesetdevconfig,'+
    'tapiclient_linesetlinedevstatus,tapiclient_linesetmediacontrol,'+
    'tapiclient_linesetmediamode,tapiclient_linesetterminal,'+
    'tapiclient_linesettolllist,tapiclient_load,tapiclient_phoneconfigdialog,'+
    'tapiclient_phoneopen,tapigetlocationinfo,tapigetlocationinfoa,'+
    'tapigetlocationinfow,tapirequestdrop,tapirequestmakecall,tapirequestmakecalla,'+
    'tapirequestmakecallw,tapirequestmediacall,tapirequestmediacalla,'+
    'tapirequestmediacallw,tapiwndproc,tbsaveparams,tcaddclassmap,tcaddfilter,'+
    'tcaddflow,tccloseinterface,tcdeletefilter,tcdeleteflow,tcderegisterclient,'+
    'tcdrain,tcenumerateflows,tcenumerateinterfaces,tcflow,tcflush,tcgetattr,'+
    'tcgetflowname,tcgetflownamea,tcgetflownamew,tcgetpgrp,tcmodifyflow,'+
    'tcopeninterface,tcopeninterfacea,tcopeninterfacew,tcpxsum,tcqueryflow,'+
    'tcqueryflowa,tcqueryfloww,tcqueryinterface,tcregisterclient,tcsendbreak,'+
    'tcsetattr,tcsetflow,tcsetflowa,tcsetfloww,tcsetinterface,tcsetpgrp,'+
    'tdibuildnetbiosaddress,tdibuildnetbiosaddressea,tdicopybuffertomdl,'+
    'tdicopybuffertomdlwithreservedmappingatdpclevel,tdicopymdlchaintomdlchain,'+
    'tdicopymdltobuffer,tdidefaultchainedrcvdatagramhandler,'+
    'tdidefaultchainedrcvexpeditedhandler,tdidefaultchainedreceivehandler,'+
    'tdidefaultconnecthandler,tdidefaultdisconnecthandler,tdidefaulterrorhandler,'+
    'tdidefaultrcvdatagramhandler,tdidefaultrcvexpeditedhandler,'+
    'tdidefaultreceivehandler,tdidefaultsendpossiblehandler,'+
    'tdideregisteraddresschangehandler,tdideregisterdeviceobject,'+
    'tdideregisternetaddress,tdideregisternotificationhandler,'+
    'tdideregisterpnphandlers,tdideregisterprovider,tdienumerateaddresses,'+
    'tdiinitialize,tdimapuserrequest,tdimatchpdowithchainedreceivecontext,'+
    'tdiopennetbiosaddress,tdipnppowercomplete,tdipnppowerrequest,tdiproviderready,'+
    'tdiregisteraddresschangehandler,tdiregisterdeviceobject,tdiregisternetaddress,'+
    'tdiregisternotificationhandler,tdiregisterpnphandlers,tdiregisterprovider,'+
    'tdireturnchainedreceives,terminateclients,terminatedocclients,'+
    'terminatejobobject,terminateprocess,terminatesetuplog,terminatethread,'+
    'termsrvappinstallmode,test4scchange,testb,testcolormatrix,testmemory,textout,'+
    'textouta,textoutw,textrange,thalloc,thclearerrors,thcreate,thdestroy,thfree,'+
    'thgeterrorstring,thquery,thread,thread32first,thread32next,threalloc,threstore,'+
    'thsave,thunkconnect32,thverifycount,tid32message,tilechildwindows,tilewindows,'+
    'time,time_string,timebeginperiod,timeendperiod,timegetdevcaps,timegetsystemtime,'+
    'timegettime,timekillevent,timeout,times,timesetevent,tlsalloc,tlsfree,'+
    'tlsgetvalue,tlssetvalue,toascii,toasciiex,tolower,toolhelp32readprocessmemory,'+
    'toolinfo,touchfiletimes,tounicode,tounicodeex,toupper,towerconstruct,'+
    'towerexplode,towlower,towupper,tracederegister,tracederegistera,'+
    'tracederegisterex,tracederegisterexa,tracederegisterexw,tracederegisterw,'+
    'tracedumpex,tracedumpexa,tracedumpexw,traceevent,traceeventinstance,'+
    'tracegetconsole,tracegetconsolea,tracegetconsolew,tracemessage,tracemessageva,'+
    'traceprintf,traceprintfa,traceprintfex,traceprintfexa,traceprintfexw,'+
    'traceprintfw,traceputsex,traceputsexa,traceputsexw,traceregisterex,'+
    'traceregisterexa,traceregisterexw,tracevprintfex,tracevprintfexa,'+
    'tracevprintfexw,trackmouseevent,trackpopupmenu,trackpopupmenuex,trans,'+
    'transactnamedpipe,transinfo,translateaccelerator,translateacceleratora,'+
    'translateacceleratorw,translatebitmapbits,translatecharsetinfo,translatecolors,'+
    'translateinfstring,translateinfstringex,translatemdisysaccel,translatemessage,'+
    'translatename,translatenamea,translatenamew,transmitcommchar,transmitfile,'+
    'transmitqueue,transmitspecialframe,transparentblt,transportaddrfrommtxaddr,'+
    'treeresetnamedsecurityinfo,treeresetnamedsecurityinfoa,'+
    'treeresetnamedsecurityinfow,trfilterdprindicatereceive,'+
    'trfilterdprindicatereceivecomplete,trimdsnameby,trimvirtualbuffer,trustdecode,'+
    'trusteeaccesstoobject,trusteeaccesstoobjecta,trusteeaccesstoobjectw,'+
    'trustfindissuercertificate,trustfreedecode,trustiscertificateselfsigned,'+
    'trustopenstores,tryentercriticalsection,tstline,tthittestinfo,ttyname,'+
    'tuispidllcallback,tvitem,typedef,typeinfo,tzidatetodatetime,'+
    'tzspecificlocaltimetosystemtime,ucappend,ucargbynum,uccatstr,uccmp,uccopy,'+
    'ucfind,ucgetcl,ucgetline,ucleft,uclen,uclower,ucltrim,ucmid,ucmonospace,'+
    'ucmulticat,ucopenfiledialog,ucremove,ucrep,ucrev,ucright,ucrtrim,'+
    'ucsavefiledialog,ucupper,ucwcnt,udw2str,ufromsz,uladdref,uldecodeeuc_jis,'+
    'uldecodegb2312_1980,uldecodeiso8859_1,uldecodeiso8859_7,uldecodejisx0201_1976,'+
    'uldecodejisx0208_1978,uldecodejisx0208_1983,uldecodejisx0208_nec,'+
    'uldecodejisx0212_1990,uldecodeksc5601_1987,uldecodeterminator,ulencodeeuc_jis,'+
    'ulencodegb2312_1980,ulencodeiso8859_1,ulencodeiso8859_7,ulencodejisx0201_1976,'+
    'ulencodejisx0201k_1976,ulencodejisx0201r_1976,ulencodejisx0208_1978,'+
    'ulencodejisx0208_1983,ulencodejisx0208_nec,ulencodejisx0208s_1978,'+
    'ulencodejisx0208s_1983,ulencodejisx0208s_nec,ulencodejisx0212_1990,'+
    'ulencodejisx0212s_1990,ulencodeksc5601_1987,ulencodeterminator,ulfromszhex,'+
    'ulgchartype,ulgetimecomposition,ulgetimemode,ulggetlang,ulggetpunctmask,'+
    'ulgsetlang,ulgsetpunctmask,ulpropsize,ulrelease,ulsetimemode,ulvchartype,'+
    'ulvgetlang,ulvgetpunctmask,ulvsetlang,ulvsetpunctmask,umask,uname,unbufcall,'+
    'undecoratesymbolname,undoadjustpacketbuffer,undoalignkmptr,undoalignrpcptr,'+
    'unenablerouter,unhandledexceptionfilter,unhookwindowshook,unhookwindowshookex,'+
    'unhookwinevent,uniattachminiime,unicandwndproc,unicompwndproc,'+
    'unicontextmenuwndproc,unidetachminiime,uniimeconfigure,uniimeconversionlist,'+
    'uniimedestroy,uniimeenumregisterword,uniimeescape,uniimegetregisterwordstyle,'+
    'uniimeinquire,uniimeprocesskey,uniimeregisterword,uniimeselect,'+
    'uniimesetactivecontext,uniimesetcompositionstring,uniimetoasciiex,'+
    'uniimeunregisterword,unimpersonateanyclient,uninitializeflatsb,uninitializeras,'+
    'uninotifyime,uninstallapplication,uninstallcolorprofile,uninstallcolorprofilea,'+
    'uninstallcolorprofilew,unioffcaretwndproc,unionrect,unisearchphraseprediction,'+
    'unisearchphrasepredictiona,unisearchphrasepredictionw,unistatuswndproc,'+
    'uniuiwndproc,universal_name_info,unkobj_cofree,unkobj_free,unkobj_freerows,'+
    'unkobj_scallocate,unkobj_scallocatemore,unkobj_sccoallocate,'+
    'unkobj_sccoreallocate,unkobj_scszfromidsalloc,unlink,unlinkb,unloaddriver,'+
    'unloaddriverfile,unloadkeyboardlayout,unloadperfcountertextstrings,'+
    'unloadperfcountertextstringsa,unloadperfcountertextstringsw,unloaduserprofile,'+
    'unlockblob,unlockfile,unlockfileex,unlockframe,unlockframepropertytable,'+
    'unlockframetext,unlockservicedatabase,unlockurlcacheentryfile,'+
    'unlockurlcacheentryfilea,unlockurlcacheentryfilew,unlockurlcacheentrystream,'+
    'unmapandload,unmapdebuginformation,unmapls,unmapslfixarray,unmapviewoffile,'+
    'unmarshalblob,unpackddelparam,unrealizeobject,unregisterclass,unregisterclassa,'+
    'unregisterclassw,unregistercmm,unregistercmma,unregistercmmw,'+
    'unregisterconsoleime,unregisterdevicenotification,unregistergpnotification,'+
    'unregisterhotkey,unregisteridletask,unregistertraceguids,unregistertypelib,'+
    'unregistertypelibforuser,unregisterwait,unregisterwaitex,unsealmessage,'+
    'unsetipsecptr,unsetipsecsendptr,untimeout,update,update_cumulative_block_stats,'+
    'update_tree_estimates,updatebatmeter,updatebuffersize,updatecolors,'+
    'updatedcomsettings,updatedebuginfofile,updatedebuginfofileex,updatedecoder,'+
    'updatedriverforplugandplaydevices,updatedriverforplugandplaydevicesa,'+
    'updatedriverforplugandplaydevicesw,updatedsperfstats,updateicmregkey,'+
    'updateicmregkeya,updateicmregkeyw,updatelayeredwindow,updatentmsomidinfo,'+
    'updateperfnamefiles,updateperfnamefilesa,updateperfnamefilesw,'+
    'updatepnpdevicedrivers,updateprinterregall,updateprinterreguser,updateresource,'+
    'updateresourcea,updateresourcew,updatetrace,updatetracea,updatetracew,'+
    'updateurlcachecontentpath,updatewaittimer,updatewindow,upgradeprinters,'+
    'url_components,urlapplyscheme,urlapplyschemea,urlapplyschemew,urlcanonicalize,'+
    'urlcanonicalizea,urlcanonicalizew,urlcombine,urlcombinea,urlcombinew,urlcompare,'+
    'urlcomparea,urlcomparew,urlcreatefrompath,urlcreatefrompatha,urlcreatefrompathw,'+
    'urldownload,urldownloada,urldownloadtocachefile,urldownloadtocachefilea,'+
    'urldownloadtocachefilew,urldownloadtofile,urldownloadtofilea,urldownloadtofilew,'+
    'urldownloadw,urlescape,urlescapea,urlescapew,urlgetlocation,urlgetlocationa,'+
    'urlgetlocationw,urlgetpart,urlgetparta,urlgetpartw,urlhash,urlhasha,urlhashw,'+
    'urlis,urlisa,urlisnohistory,urlisnohistorya,urlisnohistoryw,urlisopaque,'+
    'urlisopaquea,urlisopaquew,urlisw,urlmkbuildversion,urlmkgetsessionoption,'+
    'urlmksetsessionoption,urlopenblockingstream,urlopenblockingstreama,'+
    'urlopenblockingstreamw,urlopenpullstream,urlopenpullstreama,urlopenpullstreamw,'+
    'urlopenstream,urlopenstreama,urlopenstreamw,urlunescape,urlunescapea,'+
    'urlunescapew,urlzonesdetach,usbcamd_adapterreceivepacket,'+
    'usbcamd_controlvendorcommand,usbcamd_debug_logentry,usbcamd_driverentry,'+
    'usbcamd_getregistrykeyvalue,usbcamd_initializenewinterface,'+
    'usbcamd_selectalternateinterface,usbd_allocatedevicename,'+
    'usbd_calculateusbbandwidth,usbd_completerequest,usbd_createconfigurationrequest,'+
    'usbd_createconfigurationrequestex,usbd_createdevice,usbd_debug_getheap,'+
    'usbd_debug_logentry,usbd_debug_retheap,usbd_dispatch,usbd_freedevicemutex,'+
    'usbd_freedevicename,usbd_getdeviceinformation,usbd_getinterfacelength,'+
    'usbd_getpdoregistryparameter,usbd_getsuspendpowerstate,usbd_getusbdiversion,'+
    'usbd_initializedevice,usbd_makepdoname,usbd_parseconfigurationdescriptor,'+
    'usbd_parseconfigurationdescriptorex,usbd_parsedescriptors,usbd_querybustime,'+
    'usbd_registerhcdevicecapabilities,usbd_registerhcfilter,'+
    'usbd_registerhostcontroller,usbd_removedevice,usbd_restoredevice,'+
    'usbd_setsuspendpowerstate,usbd_waitdevicemutex,userhandlegrantaccess,'+
    'userinststubwrapper,useruninststubwrapper,usgcharsize,usgdecchar,'+
    'usggetbreakoption,usggetpunct,usgincchar,usgpunct,usgsetbreakoption,ustr2dw,'+
    'usvcharsize,usvdecchar,usvgetbreakoption,usvgetpunct,usvincchar,usvpunct,'+
    'usvsetbreakoption,utconvertdvtd16todvtd32,utconvertdvtd32todvtd16,'+
    'utgetdvtd16info,utgetdvtd32info,utime,utregister,utunregister,uuidcompare,'+
    'uuidcreate,uuidcreatenil,uuidcreatesequential,uuidequal,uuidfromstring,'+
    'uuidfromstringa,uuidfromstringw,uuidhash,uuidisnil,uuidtostring,uuidtostringa,'+
    'uuidtostringw,valent,validateerrorqueue,validatelctype,validatelocale,'+
    'validatepassword,validatepowerpolicies,validaterect,validatergn,varabs,varadd,'+
    'varand,varboolfromcy,varboolfromdate,varboolfromdec,varboolfromdisp,'+
    'varboolfromi1,varboolfromi2,varboolfromi4,varboolfromi8,varboolfromr4,'+
    'varboolfromr8,varboolfromstr,varboolfromui1,varboolfromui2,varboolfromui4,'+
    'varboolfromui8,varbstrcat,varbstrcmp,varbstrfrombool,varbstrfromcy,'+
    'varbstrfromdate,varbstrfromdec,varbstrfromdisp,varbstrfromi1,varbstrfromi2,'+
    'varbstrfromi4,varbstrfromi8,varbstrfromr4,varbstrfromr8,varbstrfromui1,'+
    'varbstrfromui2,varbstrfromui4,varbstrfromui8,varcat,varcmp,varcyabs,varcyadd,'+
    'varcycmp,varcycmpr8,varcyfix,varcyfrombool,varcyfromdate,varcyfromdec,'+
    'varcyfromdisp,varcyfromi1,varcyfromi2,varcyfromi4,varcyfromi8,varcyfromr4,'+
    'varcyfromr8,varcyfromstr,varcyfromui1,varcyfromui2,varcyfromui4,varcyfromui8,'+
    'varcyint,varcymul,varcymuli4,varcymuli8,varcyneg,varcyround,varcysub,'+
    'vardatefrombool,vardatefromcy,vardatefromdec,vardatefromdisp,vardatefromi1,'+
    'vardatefromi2,vardatefromi4,vardatefromi8,vardatefromr4,vardatefromr8,'+
    'vardatefromstr,vardatefromudate,vardatefromudateex,vardatefromui1,'+
    'vardatefromui2,vardatefromui4,vardatefromui8,vardecabs,vardecadd,vardeccmp,'+
    'vardeccmpr8,vardecdiv,vardecfix,vardecfrombool,vardecfromcy,vardecfromdate,'+
    'vardecfromdisp,vardecfromi1,vardecfromi2,vardecfromi4,vardecfromi8,vardecfromr4,'+
    'vardecfromr8,vardecfromstr,vardecfromui1,vardecfromui2,vardecfromui4,'+
    'vardecfromui8,vardecint,vardecmul,vardecneg,vardecround,vardecsub,vardiv,vareqv,'+
    'varfix,varformat,varformatcurrency,varformatdatetime,varformatfromtokens,'+
    'varformatnumber,varformatpercent,vari1frombool,vari1fromcy,vari1fromdate,'+
    'vari1fromdec,vari1fromdisp,vari1fromi2,vari1fromi4,vari1fromi8,vari1fromr4,'+
    'vari1fromr8,vari1fromstr,vari1fromui1,vari1fromui2,vari1fromui4,vari1fromui8,'+
    'vari2frombool,vari2fromcy,vari2fromdate,vari2fromdec,vari2fromdisp,vari2fromi1,'+
    'vari2fromi4,vari2fromi8,vari2fromr4,vari2fromr8,vari2fromstr,vari2fromui1,'+
    'vari2fromui2,vari2fromui4,vari2fromui8,vari4frombool,vari4fromcy,vari4fromdate,'+
    'vari4fromdec,vari4fromdisp,vari4fromi1,vari4fromi2,vari4fromi8,vari4fromr4,'+
    'vari4fromr8,vari4fromstr,vari4fromui1,vari4fromui2,vari4fromui4,vari4fromui8,'+
    'vari8frombool,vari8fromcy,vari8fromdate,vari8fromdec,vari8fromdisp,vari8fromi1,'+
    'vari8fromi2,vari8fromr4,vari8fromr8,vari8fromstr,vari8fromui1,vari8fromui2,'+
    'vari8fromui4,vari8fromui8,variant_userfree,variant_usermarshal,variant_usersize,'+
    'variant_userunmarshal,variantchangetype,variantchangetypeex,variantclear,'+
    'variantcopy,variantcopyind,variantinit,varianttimetodosdatetime,'+
    'varianttimetosystemtime,varidiv,varimp,varint,varlensmallinttodword,varmod,'+
    'varmonthname,varmul,varneg,varnot,varnumfromparsenum,varor,varparsenumfromstr,'+
    'varpow,varr4cmpr8,varr4frombool,varr4fromcy,varr4fromdate,varr4fromdec,'+
    'varr4fromdisp,varr4fromi1,varr4fromi2,varr4fromi4,varr4fromi8,varr4fromr8,'+
    'varr4fromstr,varr4fromui1,varr4fromui2,varr4fromui4,varr4fromui8,varr8frombool,'+
    'varr8fromcy,varr8fromdate,varr8fromdec,varr8fromdisp,varr8fromi1,varr8fromi2,'+
    'varr8fromi4,varr8fromi8,varr8fromr4,varr8fromstr,varr8fromui1,varr8fromui2,'+
    'varr8fromui4,varr8fromui8,varr8pow,varr8round,varround,varsub,'+
    'vartokenizeformatstring,varudatefromdate,varui1frombool,varui1fromcy,'+
    'varui1fromdate,varui1fromdec,varui1fromdisp,varui1fromi1,varui1fromi2,'+
    'varui1fromi4,varui1fromi8,varui1fromr4,varui1fromr8,varui1fromstr,varui1fromui2,'+
    'varui1fromui4,varui1fromui8,varui2frombool,varui2fromcy,varui2fromdate,'+
    'varui2fromdec,varui2fromdisp,varui2fromi1,varui2fromi2,varui2fromi4,'+
    'varui2fromi8,varui2fromr4,varui2fromr8,varui2fromstr,varui2fromui1,'+
    'varui2fromui4,varui2fromui8,varui4frombool,varui4fromcy,varui4fromdate,'+
    'varui4fromdec,varui4fromdisp,varui4fromi1,varui4fromi2,varui4fromi4,'+
    'varui4fromi8,varui4fromr4,varui4fromr8,varui4fromstr,varui4fromui1,'+
    'varui4fromui2,varui4fromui8,varui8frombool,varui8fromcy,varui8fromdate,'+
    'varui8fromdec,varui8fromdisp,varui8fromi1,varui8fromi2,varui8fromi8,'+
    'varui8fromr4,varui8fromr8,varui8fromstr,varui8fromui1,varui8fromui2,'+
    'varui8fromui4,varweekdayname,varxor,vdbglogerror,vdbgprintex,'+
    'vdbgprintexwithprefix,vddallocatedoshandle,vddallocmem,vddassociatenthandle,'+
    'vdddeinstalliohook,vdddeinstallmemoryhook,vdddeinstalluserhook,vddexcludemem,'+
    'vddfreemem,vddincludemem,vddinstalliohook,vddinstallmemoryhook,'+
    'vddinstalluserhook,vddquerydma,vddreleasedoshandle,vddreleaseirqline,'+
    'vddrequestdma,vddreserveirqline,vddretrieventhandle,vddsetdma,vddsimulate16,'+
    'vddterminatevdm,vdmbreakthread,vdmconsoleoperation,vdmdbgattach,vdmdetectwo,'+
    'vdmdetectwow,vdmenumprocesswo,vdmenumprocesswow,vdmenumtaskwo,vdmenumtaskwow,'+
    'vdmenumtaskwowex,vdmgetaddrexpression,vdmgetcontext,vdmgetdbgflags,'+
    'vdmgetmoduleselector,vdmgetparametersinfoerror,vdmgetpointer,vdmgetsegmentinfo,'+
    'vdmgetsegtablepointer,vdmgetselectormodule,vdmgetsymbol,vdmgetthreadcontext,'+
    'vdmgetthreadselectorentry,vdmglobalfirst,vdmglobalnext,vdmismoduleloaded,'+
    'vdmkillwo,vdmkillwow,vdmmapflat,vdmmodulefirst,vdmmodulenext,'+
    'vdmoperationstarted,vdmparametersinfo,vdmprocessexception,vdmsetcontext,'+
    'vdmsetdbgflags,vdmsetthreadcontext,vdmstarttaskinwo,vdmstarttaskinwow,'+
    'vdmterminatetaskwo,vdmterminatetaskwow,vdmtraceevent,vdprintf,vectorfrombstr,'+
    'verfindfile,verfindfilea,verfindfilew,verifyconsoleiohandle,verifysignature,'+
    'verifysupervisorpassword,verifyversioninfo,verifyversioninfoa,'+
    'verifyversioninfow,verinstallfile,verinstallfilea,verinstallfilew,'+
    'verlanguagename,verlanguagenamea,verlanguagenamew,verqueryvalue,verqueryvaluea,'+
    'verqueryvalueindex,verqueryvalueindexa,verqueryvalueindexw,verqueryvaluew,'+
    'versetconditionmask,version,verticaltile,vf2dw,vf2up,vffaildevicenode,'+
    'vffaildriver,vffailsystembios,vfisverificationenabled,vfreeerrors,vgetlasterror,'+
    'videoforwindowsversion,videoportacquiredevicelock,videoportacquirespinlock,'+
    'videoportacquirespinlockatdpclevel,videoportallocatebuffer,'+
    'videoportallocatecommonbuffer,videoportallocatecontiguousmemory,'+
    'videoportallocatepool,videoportassociateeventswithdmahandle,'+
    'videoportcheckfordeviceexistance,videoportcheckfordeviceexistence,'+
    'videoportclearevent,videoportcomparememory,videoportcompletedma,'+
    'videoportcreateevent,videoportcreatesecondarydisplay,videoportcreatespinlock,'+
    'videoportdbgreportcomplete,videoportdbgreportcreate,'+
    'videoportdbgreportsecondarydata,videoportddcmonitorhelper,videoportdebugprint,'+
    'videoportdeleteevent,videoportdeletespinlock,videoportdisableinterrupt,'+
    'videoportdodma,videoportenableinterrupt,videoportenumeratechildren,'+
    'videoportflushregistry,videoportfreecommonbuffer,videoportfreedevicebase,'+
    'videoportfreepool,videoportgetaccessranges,videoportgetagpservices,'+
    'videoportgetassociateddeviceextension,videoportgetassociateddeviceid,'+
    'videoportgetbusdata,videoportgetbytesused,videoportgetcommonbuffer,'+
    'videoportgetcurrentirql,videoportgetdevicebase,videoportgetdevicedata,'+
    'videoportgetdmaadapter,videoportgetdmacontext,videoportgetmdl,'+
    'videoportgetregistryparameters,videoportgetromimage,videoportgetversion,'+
    'videoportgetvgastatus,videoportinitialize,videoportint10,videoportlockbuffer,'+
    'videoportlockpages,videoportlogerror,videoportmapbankedmemory,'+
    'videoportmapdmamemory,videoportmapmemory,videoportmovememory,'+
    'videoportputdmaadapter,videoportqueryperformancecounter,videoportqueryservices,'+
    'videoportquerysystemtime,videoportqueuedpc,videoportreadportbufferuchar,'+
    'videoportreadportbufferulong,videoportreadportbufferushort,'+
    'videoportreadportuchar,videoportreadportulong,videoportreadportushort,'+
    'videoportreadregisterbufferuchar,videoportreadregisterbufferulong,'+
    'videoportreadregisterbufferushort,videoportreadregisteruchar,'+
    'videoportreadregisterulong,videoportreadregisterushort,videoportreadstateevent,'+
    'videoportregisterbugcheckcallback,videoportreleasebuffer,'+
    'videoportreleasecommonbuffer,videoportreleasedevicelock,'+
    'videoportreleasespinlock,videoportreleasespinlockfromdpclevel,videoportscanrom,'+
    'videoportsetbusdata,videoportsetbytesused,videoportsetdmacontext,'+
    'videoportsetevent,videoportsetregistryparameters,'+
    'videoportsettrappedemulatorports,videoportsignaldmacomplete,'+
    'videoportstallexecution,videoportstartdma,videoportstarttimer,'+
    'videoportstoptimer,videoportsynchronizeexecution,videoportunlockbuffer,'+
    'videoportunlockpages,videoportunmapdmamemory,videoportunmapmemory,'+
    'videoportverifyaccessranges,videoportwaitforsingleobject,'+
    'videoportwriteportbufferuchar,videoportwriteportbufferulong,'+
    'videoportwriteportbufferushort,videoportwriteportuchar,videoportwriteportulong,'+
    'videoportwriteportushort,videoportwriteregisterbufferuchar,'+
    'videoportwriteregisterbufferulong,videoportwriteregisterbufferushort,'+
    'videoportwriteregisteruchar,videoportwriteregisterulong,'+
    'videoportwriteregisterushort,videoportzerodevicememory,videoportzeromemory,'+
    'videothunk32,vidmemfree,viewsetupactionlog,virtualalloc,virtualallocex,'+
    'virtualbufferexceptionhandler,virtualfree,virtualfreeex,virtuallock,'+
    'virtualprotect,virtualprotectex,virtualquery,virtualqueryex,virtualunlock,'+
    'vkkeyscan,vkkeyscana,vkkeyscanex,vkkeyscanexa,vkkeyscanexw,vkkeyscanw,'+
    'volumeclassinstaller,vpnotifyeadata,vresetdecodingstatus,vresetencodingstatus,'+
    'vretrievedrivererrorsrowcol,vsprintf,vswprintf,w32dispatch,'+
    'w32hungappnotifythread,w32init,waitcommevent,waitfordebugevent,waitforinputidle,'+
    'waitformachinepolicyforegroundprocessing,waitformultipleobjects,'+
    'waitformultipleobjectsex,waitforntmsnotification,waitforntmsoperatorrequest,'+
    'waitforprinterchange,waitforsingleobject,waitforsingleobjectex,'+
    'waitforspoolerinitialization,waitforuserpolicyforegroundprocessing,waitifidle,'+
    'waitmessage,waitnamedpipe,waitnamedpipea,waitnamedpipew,waitpid,wantarrows,'+
    'waveinaddbuffer,waveinclose,waveingetdevcaps,waveingetdevcapsa,'+
    'waveingetdevcapsw,waveingeterrortext,waveingeterrortexta,waveingeterrortextw,'+
    'waveingetid,waveingetnumdevs,waveingetposition,waveinmessage,waveinopen,'+
    'waveinprepareheader,waveinreset,waveinstart,waveinstop,waveinunprepareheader,'+
    'waveoutbreakloop,waveoutclose,waveoutgetdevcaps,waveoutgetdevcapsa,'+
    'waveoutgetdevcapsw,waveoutgeterrortext,waveoutgeterrortexta,'+
    'waveoutgeterrortextw,waveoutgetid,waveoutgetnumdevs,waveoutgetpitch,'+
    'waveoutgetplaybackrate,waveoutgetposition,waveoutgetvolume,waveoutmessage,'+
    'waveoutopen,waveoutpause,waveoutprepareheader,waveoutreset,waveoutrestart,'+
    'waveoutsetpitch,waveoutsetplaybackrate,waveoutsetvolume,waveoutunprepareheader,'+
    'waveoutwrite,wcscat,wcschr,wcscmp,wcscpy,wcscspn,wcslen,wcsncat,wcsncmp,wcsncpy,'+
    'wcsrchr,wcsspn,wcsstr,wcstok,wcstombs,wcstoul,wdmlibiocsqinitialize,'+
    'wdmlibiocsqinitializeex,wdmlibiocsqinsertirp,wdmlibiocsqinsertirpex,'+
    'wdmlibiocsqremoveirp,wdmlibiocsqremovenextirp,wdmwmiservicemain,'+
    'wdtpinterfacepointer_userfree,wdtpinterfacepointer_usermarshal,'+
    'wdtpinterfacepointer_usersize,wdtpinterfacepointer_userunmarshal,wep,wgdlgproc,'+
    'wglchoosepixelformat,wglcopycontext,wglcreatecontext,wglcreatelayercontext,'+
    'wgldeletecontext,wgldescribelayerplane,wgldescribepixelformat,'+
    'wglgetcurrentcontext,wglgetcurrentdc,wglgetdefaultprocaddress,'+
    'wglgetlayerpaletteentries,wglgetpixelformat,wglgetprocaddress,wglmakecurrent,'+
    'wglrealizelayerpalette,wglsetlayerpaletteentries,wglsetpixelformat,'+
    'wglsharelists,wglswapbuffers,wglswaplayerbuffers,wglswapmultiplebuffers,'+
    'wglusefontbitmaps,wglusefontbitmapsa,wglusefontbitmapsw,wglusefontoutlines,'+
    'wglusefontoutlinesa,wglusefontoutlinesw,wiascreatechildappitem,'+
    'wiascreatedrvitem,wiascreateloginstance,wiascreatepropcontext,wiasdebugerror,'+
    'wiasdebugtrace,wiasdownsamplebuffer,wiasformatargs,wiasfreepropcontext,'+
    'wiasgetchangedvaluefloat,wiasgetchangedvalueguid,wiasgetchangedvaluelong,'+
    'wiasgetchangedvaluestr,wiasgetchildrencontexts,wiasgetcontextfromname,'+
    'wiasgetdrvitem,wiasgetimageinformation,wiasgetitemtype,'+
    'wiasgetpropertyattributes,wiasgetrootitem,wiasispropchanged,'+
    'wiasparseendorserstring,wiasprintdebughresult,wiasqueueevent,wiasreadmultiple,'+
    'wiasreadpropbin,wiasreadpropfloat,wiasreadpropguid,wiasreadproplong,'+
    'wiasreadpropstr,wiassendendofpage,wiassetitempropattribs,wiassetitempropnames,'+
    'wiassetpropchanged,wiassetpropertyattributes,wiassetvalidflag,'+
    'wiassetvalidlistfloat,wiassetvalidlistguid,wiassetvalidlistlong,'+
    'wiassetvalidliststr,wiassetvalidrangefloat,wiassetvalidrangelong,'+
    'wiasupdatescanrect,wiasupdatevalidformat,wiasvalidateitemproperties,'+
    'wiaswritebuftofile,wiaswritemultiple,wiaswritepagebuftofile,wiaswritepropbin,'+
    'wiaswritepropfloat,wiaswritepropguid,wiaswriteproplong,wiaswritepropstr,'+
    'wid32message,widechartomultibyte,widenpath,win32_find_data,win32deletefile,'+
    'win4assertex,windowfromaccessibleobject,'+
    'windowfromdc,windowfrompoint,windowsupdatedriversearchingpolicyui,winexec,'+
    'winhelp,winhelpa,winhelpw,winlogonlockevent,winlogonlogoffevent,'+
    'winlogonlogonevent,winlogonscreensaverevent,winlogonshutdownevent,'+
    'winlogonstartshellevent,winlogonstartupevent,winlogonunlockevent,winmmdbgout,'+
    'winmmlogoff,winmmlogon,winmmsetdebuglevel,winnlsenableime,winnlsgetenablestatus,'+
    'winnlsgetimehotkey,winntflags,winntstr,winstationactivatelicense,'+
    'winstationautoreconnect,winstationbroadcastsystemmessage,'+
    'winstationcheckloopback,winstationcloseserver,winstationconnect,'+
    'winstationconnecta,winstationconnectcallback,winstationconnectw,'+
    'winstationdisconnect,winstationenumerate,winstationenumerate_indexed,'+
    'winstationenumerate_indexeda,winstationenumerate_indexedw,winstationenumeratea,'+
    'winstationenumeratelicenses,winstationenumerateprocesses,winstationenumeratew,'+
    'winstationfreegapmemory,winstationfreememory,winstationgeneratelicense,'+
    'winstationgetallprocesses,winstationgetlanadaptername,'+
    'winstationgetlanadapternamea,winstationgetlanadapternamew,'+
    'winstationgetmachinepolicy,winstationgetprocesssid,'+
    'winstationgettermsrvcountersvalue,winstationinstalllicense,'+
    'winstationishelpassistantsession,winstationnamefromlogonid,'+
    'winstationnamefromlogonida,winstationnamefromlogonidw,winstationntsddebug,'+
    'winstationopenserver,winstationopenservera,winstationopenserverw,'+
    'winstationqueryinformation,winstationqueryinformationa,'+
    'winstationqueryinformationw,winstationquerylicense,'+
    'winstationquerylogoncredentials,winstationquerylogoncredentialsw,'+
    'winstationqueryupdaterequired,winstationregisterconsolenotification,'+
    'winstationremovelicense,winstationrename,winstationrenamea,winstationrenamew,'+
    'winstationrequestsessionslist,winstationreset,winstationsendmessage,'+
    'winstationsendmessagea,winstationsendmessagew,winstationsendwindowmessage,'+
    'winstationserverping,winstationsetinformation,winstationsetinformationa,'+
    'winstationsetinformationw,winstationsetpoolcount,winstationshadow,'+
    'winstationshadowstop,winstationshutdownsystem,winstationterminateprocess,'+
    'winstationunregisterconsolenotification,winstationvirtualopen,'+
    'winstationwaitsystemevent,wintrustaddactionid,wintrustadddefaultforusage,'+
    'wintrustcertificatetrust,wintrustgetdefaultforusage,wintrustgetregpolicyflags,'+
    'wintrustloadfunctionpointers,wintrustremoveactionid,wintrustsetregpolicyflags,'+
    'winverifytrust,winverifytrustex,wizardfree,wmcreatebackuprestorer,'+
    'wmcreateeditor,wmcreateindexer,wmcreateprofilemanager,wmcreatereader,'+
    'wmcreatereaderpriv,wmcreatesyncreader,wmcreatewriter,wmcreatewriterfilesink,'+
    'wmcreatewriternetworksink,wmcreatewriterpriv,wmcreatewriterpushsink,'+
    'wmicloseblock,wmiclosetracewithcursor,wmicompleterequest,wmiconverttimestamp,'+
    'wmidevinsttoinstancename,wmidevinsttoinstancenamea,wmidevinsttoinstancenamew,'+
    'wmienumerateguids,wmiexecutemethod,wmiexecutemethoda,wmiexecutemethodw,'+
    'wmifilehandletoinstancename,wmifilehandletoinstancenamea,'+
    'wmifilehandletoinstancenamew,wmifireevent,wmiflushtrace,wmifreebuffer,'+
    'wmigetfirsttraceoffset,wmigetnextevent,wmigettraceheader,'+
    'wmimofenumerateresources,wmimofenumerateresourcesa,wmimofenumerateresourcesw,'+
    'wminotificationregistration,wminotificationregistrationa,'+
    'wminotificationregistrationw,wmiopenblock,wmiopentracewithcursor,'+
    'wmiparsetraceevent,wmiqueryalldata,wmiqueryalldataa,wmiqueryalldatamultiple,'+
    'wmiqueryalldatamultiplea,wmiqueryalldatamultiplew,wmiqueryalldataw,'+
    'wmiqueryguidinformation,wmiquerysingleinstance,wmiquerysingleinstancea,'+
    'wmiquerysingleinstancemultiple,wmiquerysingleinstancemultiplea,'+
    'wmiquerysingleinstancemultiplew,wmiquerysingleinstancew,wmiquerytrace,'+
    'wmiquerytraceinformation,wmireceivenotifications,wmireceivenotificationsa,'+
    'wmireceivenotificationsw,wmiscontentprotected,wmisetsingleinstance,'+
    'wmisetsingleinstancea,wmisetsingleinstancew,wmisetsingleitem,wmisetsingleitema,'+
    'wmisetsingleitemw,wmistarttrace,wmistoptrace,wmisystemcontrol,wmitracemessage,'+
    'wmitracemessageva,wmiupdatetrace,wndobj_benum,wndobj_cenumstart,'+
    'wndobj_vsetconsumer,wnetaddconnection,wnetaddconnection2,wnetaddconnection2a,'+
    'wnetaddconnection2w,wnetaddconnection3,wnetaddconnection3a,wnetaddconnection3w,'+
    'wnetaddconnectiona,wnetaddconnectionw,wnetcancelconnection,'+
    'wnetcancelconnection2,wnetcancelconnection2a,wnetcancelconnection2w,'+
    'wnetcancelconnectiona,wnetcancelconnectionw,wnetcloseenum,wnetconnectiondialog,'+
    'wnetconnectiondialog1,wnetconnectiondialog1a,wnetconnectiondialog1w,'+
    'wnetdisconnectdialog,wnetdisconnectdialog1,wnetdisconnectdialog1a,'+
    'wnetdisconnectdialog1w,wnetenumresource,wnetenumresourcea,wnetenumresourcew,'+
    'wnetgetconnection,wnetgetconnectiona,wnetgetconnectionw,wnetgetlasterror,'+
    'wnetgetlasterrora,wnetgetlasterrorw,wnetgetnetworkinformation,'+
    'wnetgetnetworkinformationa,wnetgetnetworkinformationw,wnetgetprovidername,'+
    'wnetgetprovidernamea,wnetgetprovidernamew,wnetgetresourceinformation,'+
    'wnetgetresourceinformationa,wnetgetresourceinformationw,wnetgetresourceparent,'+
    'wnetgetresourceparenta,wnetgetresourceparentw,wnetgetuniversalname,'+
    'wnetgetuniversalnamea,wnetgetuniversalnamew,wnetgetuser,wnetgetusera,'+
    'wnetgetuserw,wnetopenenum,wnetopenenuma,wnetopenenumw,wnetsetlasterror,'+
    'wnetsetlasterrora,wnetsetlasterrorw,wnetuseconnection,wnetuseconnectiona,'+
    'wnetuseconnectionw,wnsprintf,wnsprintfa,wnsprintfw,wod32message,wordcount,'+
    'wordreplace,wordtobinary,wow32drivercallback,wow32resolvehandle,'+
    'wow32resolvememory,wow32resolvemultimediahandle,wow64win32apientry,wowappexit,'+
    'wowcallback16,wowcallback16ex,wowdirectedyield16,wowfreemetafile,'+
    'wowgetvdmpointer,wowgetvdmpointerfix,wowgetvdmpointerunfix,wowglobalalloc16,'+
    'wowglobalalloclock16,wowglobalfree16,wowgloballock16,wowgloballocksize16,'+
    'wowglobalunlock16,wowglobalunlockfree16,wowhandle16,wowhandle32,wowshellexecute,'+
    'wowsyserrorbox,wowusemciavi16,wowyield16,wpucompleteoverlappedrequest,'+
    'wpugetqostemplate,wrapcompressedrtfstream,wrapprogress,wrapstoreentryid,'+
    'wrd2bin_ex,write_disk_file,write_disk_filew,write_port_buffer_uchar,'+
    'write_port_buffer_ulong,write_port_buffer_ushort,write_port_uchar,'+
    'write_port_ulong,write_port_ushort,write_register_buffer_uchar,'+
    'write_register_buffer_ulong,write_register_buffer_ushort,write_register_uchar,'+
    'write_register_ulong,write_register_ushort,write_to_disk,writeblobtofile,'+
    'writecabinetstate,writecfdatablock,writeclassstg,writeclassstm,writeconsole,'+
    'writeconsolea,writeconsoleinput,writeconsoleinputa,writeconsoleinputvdm,'+
    'writeconsoleinputvdma,writeconsoleinputvdmw,writeconsoleinputw,'+
    'writeconsoleoutput,writeconsoleoutputa,writeconsoleoutputattribute,'+
    'writeconsoleoutputcharacter,writeconsoleoutputcharactera,'+
    'writeconsoleoutputcharacterw,writeconsoleoutputw,writeconsolew,writecount,'+
    'writecrackedblobtofile,writeencryptedfileraw,writefile,writefileex,'+
    'writefilegather,writefmtusertypestg,writeglobalpwrpolicy,writehitlogging,'+
    'writeline,writeolestg,writeport,writeprinter,writeprivateprofilesection,'+
    'writeprivateprofilesectiona,writeprivateprofilesectionw,'+
    'writeprivateprofilestring,writeprivateprofilestringa,writeprivateprofilestringw,'+
    'writeprivateprofilestruct,writeprivateprofilestructa,writeprivateprofilestructw,'+
    'writeprocessmemory,writeprocessorpwrscheme,writeprofilesection,'+
    'writeprofilesectiona,writeprofilesectionw,writeprofilestring,'+
    'writeprofilestringa,writeprofilestringw,writepsz,writepsztmp,writepwrscheme,'+
    'writereptree,writestringstream,writetapemark,wsaaccept,wsaaddresstostring,'+
    'wsaaddresstostringa,wsaaddresstostringw,wsaasyncgethostbyaddr,'+
    'wsaasyncgethostbyname,wsaasyncgetprotobyname,wsaasyncgetprotobynumber,'+
    'wsaasyncgetservbyname,wsaasyncgetservbyport,wsaasyncselect,'+
    'wsacancelasyncrequest,wsacancelblockingcall,wsacleanup,wsacloseevent,wsaconnect,'+
    'wsacreateevent,wsaduplicatesocket,wsaduplicatesocketa,wsaduplicatesocketw,'+
    'wsaenumnamespaceproviders,wsaenumnamespaceprovidersa,wsaenumnamespaceprovidersw,'+
    'wsaenumnetworkevents,wsaenumprotocols,wsaenumprotocolsa,wsaenumprotocolsw,'+
    'wsaeventselect,wsagetlasterror,wsagetoverlappedresult,wsagetqosbyname,'+
    'wsagetserviceclassinfo,wsagetserviceclassinfoa,wsagetserviceclassinfow,'+
    'wsagetserviceclassnamebyclassid,wsagetserviceclassnamebyclassida,'+
    'wsagetserviceclassnamebyclassidw,wsahtonl,wsahtons,wsainstallserviceclass,'+
    'wsainstallserviceclassa,wsainstallserviceclassw,wsaioctl,wsaisblocking,'+
    'wsajoinleaf,wsalookupservicebegin,wsalookupservicebegina,wsalookupservicebeginw,'+
    'wsalookupserviceend,wsalookupservicenext,wsalookupservicenexta,'+
    'wsalookupservicenextw,wsanspioctl,wsantohl,wsantohs,wsaproviderconfigchange,'+
    'wsarecv,wsarecvdisconnect,wsarecvex,wsarecvfrom,wsaremoveserviceclass,'+
    'wsaresetevent,wsasend,wsasenddisconnect,wsasendto,wsasetblockinghook,'+
    'wsasetevent,wsasetlasterror,wsasetservice,wsasetservicea,wsasetservicew,'+
    'wsasocket,wsasocketa,wsasocketw,wsastartup,wsastringtoaddress,'+
    'wsastringtoaddressa,wsastringtoaddressw,wsaunhookblockinghook,'+
    'wsawaitformultipleevents,wscdeinstallprovider,wscenablensprovider,'+
    'wscenumprotocols,wscgetproviderpath,wscinstallnamespace,wscinstallprovider,'+
    'wscinstallqostemplate,wscremoveqostemplate,wscuninstallnamespace,'+
    'wscupdateprovider,wscwritenamespaceorder,wscwriteproviderorder,wshell,'+
    'wshenumprotocols,wshgetsockaddrtype,wshgetsocketinformation,'+
    'wshgetwildcardsockaddr,wshgetwinsockmapping,wshnotify,wshopensocket,'+
    'wshsetsocketinformation,wsprintf,wsprintfa,wsprintfw,wtfreeevent,wtfreetimer,'+
    'wthelpercertcheckvalidsignature,wthelpercertisselfsigned,wthelpercheckcertusage,'+
    'wthelpergetagencyinfo,wthelpergetfilehandle,wthelpergetfilehash,'+
    'wthelpergetfilename,wthelpergetknownusages,wthelpergetprovcertfromchain,'+
    'wthelpergetprovprivatedatafromchain,wthelpergetprovsignerfromchain,'+
    'wthelperisinrootstore,wthelperopenknownstores,wthelperprovdatafromstatedata,'+
    'wtok,wtscloseserver,wtsdisconnectsession,wtsenumerateprocesses,'+
    'wtsenumerateprocessesa,wtsenumerateprocessesw,wtsenumerateservers,'+
    'wtsenumerateserversa,wtsenumerateserversw,wtsenumeratesessions,'+
    'wtsenumeratesessionsa,wtsenumeratesessionsw,wtsfreememory,'+
    'wtsgetactiveconsolesessionid,wtslogoffsession,wtsopenserver,wtsopenservera,'+
    'wtsopenserverw,wtsquerysessioninformation,wtsquerysessioninformationa,'+
    'wtsquerysessioninformationw,wtsqueryuserconfig,wtsqueryuserconfiga,'+
    'wtsqueryuserconfigw,wtsqueryusertoken,wtsregistersessionnotification,'+
    'wtssendmessage,wtssendmessagea,wtssendmessagew,wtssetsessioninformation,'+
    'wtssetsessioninformationa,wtssetsessioninformationw,wtssetuserconfig,'+
    'wtssetuserconfiga,wtssetuserconfigw,wtsshutdownsystem,wtsterminateprocess,'+
    'wtsunregistersessionnotification,wtsvirtualchannelclose,wtsvirtualchannelopen,'+
    'wtsvirtualchannelpurgeinput,wtsvirtualchannelpurgeoutput,wtsvirtualchannelquery,'+
    'wtsvirtualchannelread,wtsvirtualchannelwrite,wtswaitsystemevent,wvnsprintf,'+
    'wvnsprintfa,wvnsprintfw,wvsprintf,wvsprintfa,wvsprintfw,'+
    'wvtasn1catmemberinfodecode,wvtasn1catmemberinfoencode,wvtasn1catnamevaluedecode,'+
    'wvtasn1catnamevalueencode,wvtasn1spcfinancialcriteriainfodecode,'+
    'wvtasn1spcfinancialcriteriainfoencode,wvtasn1spcindirectdatacontentdecode,'+
    'wvtasn1spcindirectdatacontentencode,wvtasn1spclinkdecode,wvtasn1spclinkencode,'+
    'wvtasn1spcminimalcriteriainfodecode,wvtasn1spcminimalcriteriainfoencode,'+
    'wvtasn1spcpeimagedatadecode,wvtasn1spcpeimagedataencode,wvtasn1spcsiginfodecode,'+
    'wvtasn1spcsiginfoencode,wvtasn1spcspagencyinfodecode,'+
    'wvtasn1spcspagencyinfoencode,wvtasn1spcspopusinfodecode,'+
    'wvtasn1spcspopusinfoencode,wvtasn1spcstatementtypedecode,'+
    'wvtasn1spcstatementtypeencode,xcvdata,xcvdataw,xformobj_bapplyxform,'+
    'xformobj_igetfloatobjxform,xformobj_igetxform,xipdispatch,xlateobj_cgetpalette,'+
    'xlateobj_hgetcolortransform,xlateobj_ixlate,xlateobj_pivector,xordata,'+
    'xregthunkentry,xscaptureparameters,xschecksmbdescriptor,'+
    'xsconvertserverenumbuffer,xsdupstrtowstr,xsdupwstrtostr,xsi_netnamecanonicalize,'+
    'xsi_netnamecompare,xsi_netnamevalidate,xsi_netpathcanonicalize,'+
    'xsi_netpathcompare,xsi_netpathtype,xsnetaccessadd,xsnetaccessdel,'+
    'xsnetaccessenum,xsnetaccessgetinfo,xsnetaccessgetuserperms,xsnetaccesssetinfo,'+
    'xsnetaccountdeltas,xsnetaccountsync,xsnetbuildgetinfo,xsnetchardevcontrol,'+
    'xsnetchardevenum,xsnetchardevgetinfo,xsnetchardevqenum,xsnetchardevqgetinfo,'+
    'xsnetchardevqpurge,xsnetchardevqpurgeself,xsnetchardevqsetinfo,'+
    'xsnetconnectionenum,xsnetfileclose2,xsnetfileenum2,xsnetfilegetinfo2,'+
    'xsnetgetdcname,xsnetgroupadd,xsnetgroupadduser,xsnetgroupdel,xsnetgroupdeluser,'+
    'xsnetgroupenum,xsnetgroupgetinfo,xsnetgroupgetusers,xsnetgroupsetinfo,'+
    'xsnetgroupsetusers,xsnetlogonenum,xsnetmessagebuffersend,xsnetmessagenameadd,'+
    'xsnetmessagenamedel,xsnetmessagenameenum,xsnetmessagenamegetinfo,'+
    'xsnetprintdestadd,xsnetprintdestcontrol,xsnetprintdestdel,xsnetprintdestenum,'+
    'xsnetprintdestgetinfo,xsnetprintdestsetinfo,xsnetprintjobcontinue,'+
    'xsnetprintjobdel,xsnetprintjobenum,xsnetprintjobgetinfo,xsnetprintjobpause,'+
    'xsnetprintjobsetinfo,xsnetprintqadd,xsnetprintqcontinue,xsnetprintqdel,'+
    'xsnetprintqenum,xsnetprintqgetinfo,xsnetprintqpause,xsnetprintqpurge,'+
    'xsnetprintqsetinfo,xsnetremotetod,xsnetserverauthenticate,xsnetserverdiskenum,'+
    'xsnetserverenum2,xsnetserverenum3,xsnetservergetinfo,xsnetserverpasswordset,'+
    'xsnetserverreqchallenge,xsnetserversetinfo,xsnetservicecontrol,xsnetserviceenum,'+
    'xsnetservicegetinfo,xsnetserviceinstall,xsnetsessiondel,xsnetsessionenum,'+
    'xsnetsessiongetinfo,xsnetshareadd,xsnetsharecheck,xsnetsharedel,xsnetshareenum,'+
    'xsnetsharegetinfo,xsnetsharesetinfo,xsnetstatisticsget2,xsnetunsupportedapi,'+
    'xsnetuseadd,xsnetusedel,xsnetuseenum,xsnetusegetinfo,xsnetuseradd2,xsnetuserdel,'+
    'xsnetuserenum,xsnetuserenum2,xsnetusergetgroups,xsnetusergetinfo,'+
    'xsnetusermodalsget,xsnetusermodalsset,xsnetuserpasswordset2,xsnetusersetgroups,'+
    'xsnetusersetinfo,xsnetusersetinfo2,xsnetwkstagetinfo,xsnetwkstasetinfo,'+
    'xsnetwkstasetuid,xsnetwkstauserlogoff,xsnetwkstauserlogon,'+
    'xssamoemchangepassworduser2_p,xssetparameters,xtoa,xtow,year,ymdhmstodatetime,'+
    'zombifyactctx,zwacceptconnectport,zwaccesscheck,zwaccesscheckandauditalarm,'+
    'zwaccesscheckbytype,zwaccesscheckbytypeandauditalarm,'+
    'zwaccesscheckbytyperesultlist,zwaccesscheckbytyperesultlistandauditalarm,'+
    'zwaccesscheckbytyperesultlistandauditalarmbyhandle,zwaddatom,zwaddbootentry,'+
    'zwadddriverentry,zwadjustgroupstoken,zwadjustprivilegestoken,'+
    'zwalertresumethread,zwalertthread,zwallocatelocallyuniqueid,'+
    'zwallocateuserphysicalpages,zwallocateuuids,zwallocatevirtualmemory,'+
    'zwaremappedfilesthesame,zwassignprocesstojobobject,zwcallbackreturn,'+
    'zwcanceldevicewakeuprequest,zwcanceliofile,zwcanceltimer,zwclearevent,zwclose,'+
    'zwcloseobjectauditalarm,zwcompactkeys,zwcomparetokens,zwcompleteconnectport,'+
    'zwcompresskey,zwconnectport,zwcontinue,zwcreatedebugobject,'+
    'zwcreatedirectoryobject,zwcreateevent,zwcreateeventpair,zwcreatefile,'+
    'zwcreateiocompletion,zwcreatejobobject,zwcreatejobset,zwcreatekey,'+
    'zwcreatekeyedevent,zwcreatemailslotfile,zwcreatemutant,zwcreatenamedpipefile,'+
    'zwcreatepagingfile,zwcreateport,zwcreateprocess,zwcreateprocessex,'+
    'zwcreateprofile,zwcreatesection,zwcreatesemaphore,zwcreatesymboliclinkobject,'+
    'zwcreatethread,zwcreatetimer,zwcreatetoken,zwcreatewaitableport,'+
    'zwdebugactiveprocess,zwdebugcontinue,zwdelayexecution,zwdeleteatom,'+
    'zwdeletebootentry,zwdeletedriverentry,zwdeletefile,zwdeletekey,'+
    'zwdeleteobjectauditalarm,zwdeletevaluekey,zwdeviceiocontrolfile,zwdisplaystring,'+
    'zwduplicateobject,zwduplicatetoken,zwenumeratebootentries,'+
    'zwenumeratedriverentries,zwenumeratekey,zwenumeratesystemenvironmentvaluesex,'+
    'zwenumeratevaluekey,zwextendsection,zwfiltertoken,zwfindatom,zwflushbuffersfile,'+
    'zwflushinstructioncache,zwflushkey,zwflushvirtualmemory,zwflushwritebuffer,'+
    'zwfreeuserphysicalpages,zwfreevirtualmemory,zwfscontrolfile,zwgetcontextthread,'+
    'zwgetdevicepowerstate,zwgetplugplayevent,zwgetwritewatch,'+
    'zwimpersonateanonymoustoken,zwimpersonateclientofport,zwimpersonatethread,'+
    'zwinitializeregistry,zwinitiatepoweraction,zwisprocessinjob,'+
    'zwissystemresumeautomatic,zwlistenport,zwloaddriver,zwloadkey,zwloadkey2,'+
    'zwlockfile,zwlockproductactivationkeys,zwlockregistrykey,zwlockvirtualmemory,'+
    'zwmakepermanentobject,zwmaketemporaryobject,zwmapuserphysicalpages,'+
    'zwmapuserphysicalpagesscatter,zwmapviewofsection,zwmodifybootentry,'+
    'zwmodifydriverentry,zwnotifychangedirectoryfile,zwnotifychangekey,'+
    'zwnotifychangemultiplekeys,zwopendirectoryobject,zwopenevent,zwopeneventpair,'+
    'zwopenfile,zwopeniocompletion,zwopenjobobject,zwopenkey,zwopenkeyedevent,'+
    'zwopenmutant,zwopenobjectauditalarm,zwopenprocess,zwopenprocesstoken,'+
    'zwopenprocesstokenex,zwopensection,zwopensemaphore,zwopensymboliclinkobject,'+
    'zwopenthread,zwopenthreadtoken,zwopenthreadtokenex,zwopentimer,'+
    'zwplugplaycontrol,zwpowerinformation,zwprivilegecheck,'+
    'zwprivilegedserviceauditalarm,zwprivilegeobjectauditalarm,'+
    'zwprotectvirtualmemory,zwpulseevent,zwqueryattributesfile,zwquerybootentryorder,'+
    'zwquerybootoptions,zwquerydebugfilterstate,zwquerydefaultlocale,'+
    'zwquerydefaultuilanguage,zwquerydirectoryfile,zwquerydirectoryobject,'+
    'zwquerydriverentryorder,zwqueryeafile,zwqueryevent,zwqueryfullattributesfile,'+
    'zwqueryinformationatom,zwqueryinformationfile,zwqueryinformationjobobject,'+
    'zwqueryinformationport,zwqueryinformationprocess,zwqueryinformationthread,'+
    'zwqueryinformationtoken,zwqueryinstalluilanguage,zwqueryintervalprofile,'+
    'zwqueryiocompletion,zwquerykey,zwquerymultiplevaluekey,zwquerymutant,'+
    'zwqueryobject,zwqueryopensubkeys,zwqueryperformancecounter,'+
    'zwqueryportinformationprocess,zwqueryquotainformationfile,zwquerysection,'+
    'zwquerysecurityobject,zwquerysemaphore,zwquerysymboliclinkobject,'+
    'zwquerysystemenvironmentvalue,zwquerysystemenvironmentvalueex,'+
    'zwquerysysteminformation,zwquerysystemtime,zwquerytimer,zwquerytimerresolution,'+
    'zwqueryvaluekey,zwqueryvirtualmemory,zwqueryvolumeinformationfile,'+
    'zwqueueapcthread,zwraiseexception,zwraiseharderror,zwreadfile,zwreadfilescatter,'+
    'zwreadrequestdata,zwreadvirtualmemory,zwregisterthreadterminateport,'+
    'zwreleasekeyedevent,zwreleasemutant,zwreleasesemaphore,zwremoveiocompletion,'+
    'zwremoveprocessdebug,zwrenamekey,zwreplacekey,zwreplyport,'+
    'zwreplywaitreceiveport,zwreplywaitreceiveportex,zwreplywaitreplyport,'+
    'zwrequestdevicewakeup,zwrequestport,zwrequestwaitreplyport,'+
    'zwrequestwakeuplatency,zwresetevent,zwresetwritewatch,zwrestorekey,'+
    'zwresumeprocess,zwresumethread,zwsavekey,zwsavekeyex,zwsavemergedkeys,'+
    'zwsecureconnectport,zwsetbootentryorder,zwsetbootoptions,zwsetcontextthread,'+
    'zwsetdebugfilterstate,zwsetdefaultharderrorport,zwsetdefaultlocale,'+
    'zwsetdefaultuilanguage,zwsetdriverentryorder,zwseteafile,zwsetevent,'+
    'zwseteventboostpriority,zwsethigheventpair,zwsethighwaitloweventpair,'+
    'zwsetinformationdebugobject,zwsetinformationfile,zwsetinformationjobobject,'+
    'zwsetinformationkey,zwsetinformationobject,zwsetinformationprocess,'+
    'zwsetinformationthread,zwsetinformationtoken,zwsetintervalprofile,'+
    'zwsetiocompletion,zwsetldtentries,zwsetloweventpair,zwsetlowwaithigheventpair,'+
    'zwsetquotainformationfile,zwsetsecurityobject,zwsetsystemenvironmentvalue,'+
    'zwsetsystemenvironmentvalueex,zwsetsysteminformation,zwsetsystempowerstate,'+
    'zwsetsystemtime,zwsetthreadexecutionstate,zwsettimer,zwsettimerresolution,'+
    'zwsetuuidseed,zwsetvaluekey,zwsetvolumeinformationfile,zwshutdownsystem,'+
    'zwsignalandwaitforsingleobject,zwstartprofile,zwstopprofile,zwsuspendprocess,'+
    'zwsuspendthread,zwsystemdebugcontrol,zwterminatejobobject,zwterminateprocess,'+
    'zwterminatethread,zwtestalert,zwtraceevent,zwtranslatefilepath,zwunloaddriver,'+
    'zwunloadkey,zwunloadkeyex,zwunlockfile,zwunlockvirtualmemory,'+
    'zwunmapviewofsection,zwvdmcontrol,zwwaitfordebugevent,zwwaitforkeyedevent,'+
    'zwwaitformultipleobjects,zwwaitforsingleobject,zwwaithigheventpair,'+
    'zwwaitloweventpair,zwwritefile,zwwritefilegather,zwwriterequestdata';

//    '_trackmouseevent,abnormaltermination,abortdoc,abortpath,abortprinter,'+
//    'abortproc,abortsystemshutdown,accessntmslibrarydoor,acquiresrwlockexclusive,'+
//    'acquiresrwlockshared,activatekeyboardlayout,addatom,addclipboardformatlistener,'+
//    'adderexcludedapplication,addfontmemresourceex,addfontresource,addfontresourceex,'+
//    'addform,addjob,addmonitor,addntmsmediatype,addport,addprinter,addprinterconnection,'+
//    'addprinterdriver,addprinterdriverex,addprintprocessor,addprintprovidor,'+
//    'addsidtoboundarydescriptor,adduserstoencryptedfile,addvectoredexceptionhandler,'+
//    'adjustwindowrect,adjustwindowrectex,advanceddocumentproperties,alertsamplesavail,'+
//    'allocatentmsmedia,allocateuserphysicalpages,allocateuserphysicalpagesnuma,'+
//    'allocconsole,allowsetforegroundwindow,alphablend,anglearc,animatepalette,'+
//    'animatewindow,anypopup,apcproc,appendmenu,applicationrecoveryfinished,'+
//    'applicationrecoveryinprogress,arc,arcto,arefileapisansi,arrangeiconicwindows,'+
//    'assignprocesstojobobject,attachconsole,attachthreadinput,avquerysystemresponsiveness,'+
//    'avrevertmmthreadcharacteristics,avrtcreatethreadorderinggroup,'+
//    'avrtcreatethreadorderinggroupex,avrtdeletethreadorderinggroup,'+
//    'avrtjointhreadorderinggroup,avrtleavethreadorderinggroup,avrtwaitonthreadorderinggroup,'+
//    'avsetmmmaxthreadcharacteristics,avsetmmthreadcharacteristics,avsetmmthreadpriority,'+
//    'backupeventlog,backupread,backupseek,backupwrite,beep,begindeferwindowpos,'+
//    'beginntmsdevicechangedetection,beginpaint,beginpath,beginupdateresource,'+
//    'bindiocompletioncallback,bitblt,blockinput,bringwindowtotop,'+
//    'broadcastsystemmessage,broadcastsystemmessageex,buffercallback,buildcommdcb,'+
//    'buildcommdcbandtimeouts,callbackmayrunlong,callmsgfilter,callnamedpipe,'+
//    'callnexthookex,callntpowerinformation,callwindowproc,callwndproc,callwndretproc,'+
//    'canceldc,cancelio,cancelioex,cancelntmslibraryrequest,cancelntmsoperatorrequest,'+
//    'cancelsynchronousio,cancelthreadpoolio,cancelwaitabletimer,canuserwritepwrscheme,'+
//    'cascadewindows,cbtproc,changeclipboardchain,changedisplaysettings,changedisplaysettingsex,'+
//    'changentmsmediatype,changeserviceconfig,changeserviceconfig2,changetimerqueuetimer,'+
//    'changewindowmessagefilter,charlower,charlowerbuff,charnext,charnextexa,charprev,'+
//    'charprevexa,chartooem,chartooembuff,charupper,charupperbuff,checkdlgbutton,'+
//    'checkmenuitem,checkmenuradioitem,checknamelegaldos8dot3,checkradiobutton,'+
//    'checkremotedebuggerpresent,childwindowfrompoint,childwindowfrompointex,'+
//    'chord,claimmedialabel,cleanntmsdrive,clearcommbreak,clearcommerror,cleareventlog,'+
//    'clienttoscreen,clipcursor,closeclipboard,closedesktop,closeenhmetafile,'+
//    'closeeventlog,closefigure,closehandle,closemetafile,closentmsnotification,'+
//    'closentmssession,closeprinter,closeprivatenamespace,closeservicehandle,'+
//    'closethreadpool,closethreadpoolcleanupgroup,closethreadpoolcleanupgroupmembers,'+
//    'closethreadpoolio,closethreadpooltimer,closethreadpoolwait,closethreadpoolwork,'+
//    'closethreadwaitchainsession,closetrace,closewindow,closewindowstation,combinergn,'+
//    'combinetransform,commandlinetoargvw,commconfigdialog,comparefiletime,comparestring,'+
//    'configureport,connectnamedpipe,connecttoprinterdlg,continuedebugevent,controlcallback,'+
//    'controlservice,controlserviceex,controltrace,convertdefaultlocale,convertfibertothread,'+
//    'convertthreadtofiber,convertthreadtofiberex,copyacceleratortable,copycursor,'+
//    'copyenhmetafile,copyfile,copyfileex,copyicon,copyimage,copymemory,copymetafile,'+
//    'copyprogressroutine,copyrect,countclipboardformats,counterpathcallback,'+
//    'createacceleratortable,createbitmap,createbitmapindirect,createboundarydescriptor,'+
//    'createbrushindirect,createcaret,createcompatiblebitmap,createcompatibledc,'+
//    'createconsolescreenbuffer,createcursor,createdc,createdesktop,createdesktopex,'+
//    'createdibitmap,createdibpatternbrush,createdibpatternbrushpt,createdibsection,'+
//    'createdialog,createdialogindirect,createdialogindirectparam,createdialogparam,'+
//    'createdirectory,createdirectoryex,creatediscardablebitmap,createellipticrgn,'+
//    'createellipticrgnindirect,createenhmetafile,createevent,createeventex,createfiber,'+
//    'createfiberex,createfile,createfilemapping,createfilemappingnuma,createfont,'+
//    'createfontindirect,createfontindirectex,createhalftonepalette,createhardlink,'+
//    'createhatchbrush,createic,createicon,createiconfromresource,createiconfromresourceex,'+
//    'createiconindirect,createiocompletionport,createjobobject,createmailslot,'+
//    'createmdiwindow,createmenu,createmetafile,createmutex,createmutexex,createnamedpipe,'+
//    'createntmsmedia,createntmsmediapool,createpalette,createpatternbrush,createpen,'+
//    'createpenindirect,createpipe,createpolygonrgn,createpolypolygonrgn,createpopupmenu,'+
//    'createprivatenamespace,createprocess,createprocessasuser,createprocesswithlogonw,'+
//    'createprocesswithtokenw,createrectrgn,createrectrgnindirect,createremotethread,'+
//    'createroundrectrgn,createscalablefontresource,createsemaphore,createsemaphoreex,'+
//    'createservice,createsolidbrush,createsymboliclink,createtapepartition,'+
//    'createthread,createthreadpool,createthreadpoolcleanupgroup,createthreadpoolio,'+
//    'createthreadpooltimer,createthreadpoolwait,createthreadpoolwork,createtimerqueue,'+
//    'createtimerqueuetimer,createtoolhelp32snapshot,createtraceinstanceid,createwaitabletimer,'+
//    'createwaitabletimerex,createwindow,createwindowex,createwindowstation,'+
//    'ddeabandontransaction,ddeaccessdata,ddeadddata,ddecallback,ddeclienttransaction,'+
//    'ddecmpstringhandles,ddeconnect,ddeconnectlist,ddecreatedatahandle,ddecreatestringhandle,'+
//    'ddedisconnect,ddedisconnectlist,ddeenablecallback,ddefreedatahandle,ddefreestringhandle,'+
//    'ddegetdata,ddegetlasterror,ddeimpersonateclient,ddeinitialize,ddekeepstringhandle,'+
//    'ddenameservice,ddepostadvise,ddequeryconvinfo,ddequerynextserver,ddequerystring,'+
//    'ddereconnect,ddesetqualityofservice,ddesetuserhandle,ddeunaccessdata,'+
//    'ddeuninitialize,deallocatentmsmedia,debugactiveprocess,debugactiveprocessstop,'+
//    'debugbreak,debugbreakprocess,debugproc,debugsetprocesskillonexit,decommissionntmsmedia,'+
//    'decryptfile,deferwindowpos,defframeproc,definedosdevice,defmdichildproc,defrawinputproc,'+
//    'defwindowproc,deleteatom,deleteboundarydescriptor,deletecriticalsection,deletedc,'+
//    'deleteenhmetafile,deletefiber,deletefile,deleteform,deletemenu,deletemetafile,'+
//    'deletemonitor,deletentmsdrive,deletentmslibrary,deletentmsmedia,deletentmsmediapool,'+
//    'deletentmsmediatype,deletentmsrequests,deleteobject,deleteport,deleteprinter,'+
//    'deleteprinterconnection,deleteprinterdata,deleteprinterdataex,deleteprinterdriver,'+
//    'deleteprinterdriverex,deleteprinterkey,deleteprintprocessor,deleteprintprovidor,'+
//    'deleteprocthreadattributelist,deletepwrscheme,deleteservice,deletetimerqueue,'+
//    'deletetimerqueueex,deletetimerqueuetimer,deletevolumemountpoint,deregistereventsource,'+
//    'deregistershellhookwindow,destroyacceleratortable,destroycaret,destroycursor,'+
//    'destroyicon,destroymenu,destroythreadpoolenvironment,destroywindow,devicecapabilities,'+
//    'deviceiocontrol,disablentmsobject,disableprocesswindowsghosting,disablethreadlibrarycalls,'+
//    'disassociatecurrentthreadfromcallback,disconnectnamedpipe,dismountntmsdrive,'+
//    'dismountntmsmedia,dispatchmessage,dlgdirlist,dlgdirlistcombobox,dlgdirselectcomboboxex,'+
//    'dlgdirselectex,dllmain,dnshostnametocomputername,documentproperties,dosdatetimetofiletime,'+
//    'dptolp,dragdetect,drawanimatedrects,drawcaption,drawedge,drawescape,drawfocusrect,'+
//    'drawframecontrol,drawicon,drawiconex,drawmenubar,drawstate,drawstateproc,drawtext,'+
//    'drawtextex,duplicateencryptioninfofile,duplicateicon,editwordbreakproc,ejectdiskfromsadrive,'+
//    'ejectntmscleaner,ejectntmsmedia,ellipse,emptyclipboard,emptyworkingset,enablemenuitem,'+
//    'enablentmsobject,enablescrollbar,enabletrace,enablewindow,encryptfile,encryptiondisable,'+
//    'enddeferwindowpos,enddoc,enddocprinter,endmenu,endntmsdevicechangedetection,endpage,'+
//    'endpageprinter,endpaint,endpath,endtask,endupdateresource,enhmetafileproc,'+
//    'entercriticalsection,enumcalendarinfo,enumcalendarinfoex,enumcalendarinfoproc,'+
//    'enumcalendarinfoprocex,enumchildproc,enumchildwindows,enumclipboardformats,'+
//    'enumcodepagesproc,enumdateformats,enumdateformatsex,enumdateformatsproc,'+
//    'enumdateformatsprocex,enumdependentservices,enumdesktopproc,enumdesktops,'+
//    'enumdesktopwindows,enumdevicedrivers,enumdisplaydevices,enumdisplaymonitors,'+
//    'enumdisplaysettings,enumdisplaysettingsex,enumenhmetafile,enumeratentmsobject,'+
//    'enumeratetraceguids,enumfontfamexproc,enumfontfamilies,enumfontfamiliesex,'+
//    'enumfontfamproc,enumfonts,enumfontsproc,enumforms,enumgeoinfoproc,enuminputcontext,'+
//    'enumjobs,enumlanguagegrouplocales,enumlanguagegrouplocalesproc,enumlanguagegroupsproc,'+
//    'enumlocalesproc,enummetafile,enummetafileproc,enummonitors,enumobjects,enumobjectsproc,'+
//    'enumpagefiles,enumports,enumprinterdata,enumprinterdataex,enumprinterdrivers,'+
//    'enumprinterkey,enumprinters,enumprintprocessordatatypes,enumprintprocessors,'+
//    'enumprocesses,enumprocessmodules,enumprocessmodulesex,enumprops,enumpropsex,'+
//    'enumpwrschemes,enumregisterwordproc,enumreslangproc,enumresnameproc,enumresourcelanguages,'+
//    'enumresourcenames,numresourcetypes,enumrestypeproc,enumservicesstatus,enumservicesstatusex,'+
//    'enumsystemcodepages,enumsystemfirmwaretables,enumsystemgeoid,enumsystemlanguagegroups,'+
//    'enumsystemlocales,enumthreadwindows,enumthreadwndproc,enumtimeformats,enumtimeformatsproc,'+
//    'enumuilanguages,enumuilanguagesproc,enumwindows,enumwindowsproc,enumwindowstationproc,'+
//    'enumwindowstations,equalrect,equalrgn,erasetape,escape,escapecommfunction,eventcallback,'+
//    'eventclasscallback,excludecliprect,excludeupdatergn,exitprocess,exitthread,exitwindows,'+
//    'exitwindowsex,expandenvironmentstrings,exportntmsdatabase,extcreatepen,extcreateregion,'+
//    'extescape,extfloodfill,extractassociatedicon,extracticon,extracticonex,extselectcliprgn,'+
//    'exttextout,fatalappexit,fatalexit,fiberproc,fileencryptionstatus,fileiocompletionroutine,'+
//    'filetimetodosdatetime,filetimetolocalfiletime,filetimetosystemtime,'+
//    'fillconsoleoutputattribute,fillconsoleoutputcharacter,fillmemory,fillpath,'+
//    'fillrect,fillrgn,findatom,findclose,findclosechangenotification,'+
//    'findcloseprinterchangenotification,findfirstchangenotification,findfirstfile,'+
//    'findfirstfileex,findfirstfilenamew,findfirstprinterchangenotification,findfirststreamw,'+
//    'findfirstvolume,findfirstvolumemountpoint,findnextchangenotification,findnextfile,'+
//    'findnextfilenamew,findnextprinterchangenotification,findnextstreamw,findnextvolume,'+
//    'findnextvolumemountpoint,findresource,findresourceex,findvolumeclose,'+
//    'findvolumemountpointclose,findwindow,findwindowex,flashwindow,flashwindowex,'+
//    'flattenpath,floodfill,flsalloc,flscallback,flsfree,flsgetvalue,flssetvalue,'+
//    'flushconsoleinputbuffer,flushfilebuffers,flushinstructioncache,flushprinter,flushtrace,'+
//    'flushviewoffile,foldstring,foregroundidleproc,formatmessage,framerect,framergn,'+
//    'freeconsole,freeddelparam,freeencryptioncertificatehashlist,freeenvironmentstrings,'+
//    'freelibrary,freelibraryandexitthread,freelibrarywhencallbackreturns,freeprinternotifyinfo,'+
//    'freeuserphysicalpages,gdicomment,gdiflush,gdigetbatchlimit,gdisetbatchlimit,'+
//    'generateconsolectrlevent,getacp,getactivepwrscheme,getactivewindow,getalttabinfo,'+
//    'getancestor,getapplicationrecoverycallback,getapplicationrestartsettings,getarcdirection,'+
//    'getaspectratiofilterex,getasynckeystate,getatomname,getbinarytype,getbitmapbits,'+
//    'getbitmapdimensionex,getbkcolor,getbkmode,getboundsrect,getbrushorgex,getcalendarinfo,'+
//    'getcapture,getcaretblinktime,getcaretpos,getcharabcwidths,getcharabcwidthsfloat,'+
//    'getcharabcwidthsi,getcharacterplacement,getcharwidth,getcharwidth32,getcharwidthfloat,'+
//    'getcharwidthi,getclassinfo,getclassinfoex,getclasslong,getclasslongptr,getclassname,'+
//    'getclassword,getclientrect,getclipboarddata,getclipboardformatname,getclipboardowner,'+
//    'getclipboardsequencenumber,getclipboardviewer,getclipbox,getclipcursor,'+
//    'getcliprgn,getcoloradjustment,getcomboboxinfo,getcommandline,getcommconfig,getcommmask,'+
//    'getcommmodemstatus,getcommproperties,getcommstate,getcommtimeouts,getcompressedfilesize,'+
//    'getcomputername,getcomputernameex,getcomputerobjectname,getconsolecp,getconsolecursorinfo,'+
//    'getconsoledisplaymode,getconsolefontsize,getconsolehistoryinfo,getconsolemode,'+
//    'getconsoleoriginaltitle,getconsoleoutputcp,getconsoleprocesslist,getconsolescreenbufferinfo,'+
//    'getconsolescreenbufferinfoex,getconsoleselectioninfo,getconsoletitle,getconsolewindow,'+
//    'getcpinfo,getcpinfoex,getcurrencyformat,getcurrentconsolefont,getcurrentconsolefontex,'+
//    'getcurrentdirectory,getcurrenthwprofile,getcurrentobject,getcurrentpositionex,'+
//    'getcurrentpowerpolicies,getcurrentprocess,getcurrentprocessid,getcurrentprocessornumber,'+
//    'getcurrentthread,getcurrentthreadid,getcursor,getcursorinfo,getcursorpos,getdateformat,'+
//    'getdc,getdcbrushcolor,getdcex,getdcorgex,getdcpencolor,getdefaultcommconfig,'+
//    'getdefaultprinter,getdesktopwindow,getdevicecaps,getdevicedriverbasename,'+
//    'getdevicedriverfilename,getdevicepowerstate,getdibcolortable,getdibits,getdiskfreespace,'+
//    'getdiskfreespaceex,getdlldirectory,getdoubleclicktime,getdrivetype,'+
//    'getdynamictimezoneinformation,getenhmetafile,getenhmetafilebits,getenhmetafiledescription,'+
//    'getenhmetafileheader,getenhmetafilepaletteentries,getenvironmentstrings,'+
//    'getenvironmentvariable,geterrormode,geteventloginformation,getexceptioncode,'+
//    'getexceptioninformation,getexitcodeprocess,getexitcodethread,getexpandedname,'+
//    'getfileattributes,getfileattributesex,getfilebandwidthreservation,'+
//    'getfileinformationbyhandle,getfileinformationbyhandleex,getfilesize,getfilesizeex,'+
//    'getfiletime,getfiletype,getfileversioninfo,getfileversioninfosize,getfinalpathnamebyhandle,'+
//    'getfocus,getfontdata,getfontlanguageinfo,getfontunicoderanges,getforegroundwindow,'+
//    'getform,getfullpathname,getgeoinfo,getglyphindices,getglyphoutline,getgraphicsmode,'+
//    'getguiresources,getguithreadinfo,geticoninfo,getinputstate,getjob,getkbcodepage,'+
//    'getkerningpairs,getkeyboardlayout,getkeyboardlayoutlist,getkeyboardlayoutname,'+
//    'getkeyboardstate,getkeyboardtype,getkeynametext,getkeystate,getlargepageminimum,'+
//    'getlargestconsolewindowsize,getlastactivepopup,getlasterror,getlastinputinfo,'+
//    'getlayeredwindowattributes,getlayout,getlistboxinfo,getlocaleinfo,getlocaleinfoex,'+
//    'getlocaltime,getlogicaldrives,getlogicaldrivestrings,getlogicalprocessorinformation,'+
//    'getlongpathname,getmailslotinfo,getmapmode,getmappedfilename,getmenu,getmenubarinfo,'+
//    'getmenucheckmarkdimensions,getmenudefaultitem,getmenuinfo,getmenuitemcount,getmenuitemid,'+
//    'getmenuiteminfo,getmenuitemrect,getmenustate,getmenustring,getmessage,getmessageextrainfo,'+
//    'getmessagepos,getmessagetime,getmetafilebitsex,getmetargn,getmiterlimit,'+
//    'getmodulebasename,getmodulefilename,getmodulefilenameex,getmodulehandle,getmodulehandleex,'+
//    'getmoduleinformation,getmonitorinfo,getmousemovepointsex,getmsgproc,'+
//    'getnamedpipeclientcomputername,getnamedpipeclientprocessid,getnamedpipeclientsessionid,'+
//    'getnamedpipehandlestate,getnamedpipeinfo,getnamedpipeserverprocessid,'+
//    'getnamedpipeserversessionid,getnativesysteminfo,getnearestcolor,getnearestpaletteindex,'+
//    'getnextwindow,getntmsmediapoolname,getntmsobjectattribute,getntmsobjectinformation,'+
//    'getntmsobjectsecurity,getntmsrequestorder,getntmsuioptions,getnumaavailablememorynode,'+
//    'getnumahighestnodenumber,getnumanodeprocessormask,getnumaprocessornode,getnumaproximitynode,'+
//    'getnumberformat,getnumberformatex,getnumberofconsoleinputevents,'+
//    'getnumberofconsolemousebuttons,getnumberofeventlogrecords,getobject,getobjecttype,'+
//    'getoemcp,getoldesteventlogrecord,getopenclipboardwindow,getoutlinetextmetrics,'+
//    'getoverlappedresult,getpaletteentries,getparent,getpath,getperformanceinfo,'+
//    'getpixel,getpolyfillmode,getprinter,getprinterdata,getprinterdataex,getprinterdriver,'+
//    'getprinterdriverdirectory,getprintprocessordirectory,getpriorityclass,'+
//    'getpriorityclipboardformat,getprivateprofileint,getprivateprofilesection,'+
//    'getprivateprofilesectionnames,getprivateprofilestring,getprivateprofilestruct,'+
//    'getprocaddress,getprocessaffinitymask,getprocessdefaultlayout,getprocesshandlecount,'+
//    'getprocessheap,getprocessheaps,getprocessid,getprocessidofthread,getprocessiocounters,'+
//    'getprocessmemoryinfo,getprocesspriorityboost,getprocessshutdownparameters,'+
//    'getprocesstimes,getprocessversion,getprocesswindowstation,getprocessworkingsetsize,'+
//    'getprocessworkingsetsizeex,getproductinfo,getprofileint,getprofilesection,'+
//    'getprofilestring,getprop,getpwrcapabilities,getpwrdiskspindownrange,'+
//    'getqueuedcompletionstatus,getqueuedcompletionstatusex,getqueuestatus,getrandomrgn,'+
//    'getrasterizercaps,getrawinputbuffer,getrawinputdata,getrawinputdeviceinfo,'+
//    'getrawinputdevicelist,getregiondata,getregisteredrawinputdevices,getrgnbox,'+
//    'getrop2,getscrollbarinfo,getscrollinfo,getscrollpos,getscrollrange,getservicedisplayname,'+
//    'getservicekeyname,getshellwindow,getshortpathname,getstartupinfo,getstdhandle,'+
//    'getstockobject,getstretchbltmode,getstringtypea,getstringtypeex,getstringtypew,'+
//    'getsubmenu,getsyscolor,getsyscolorbrush,getsystemdefaultlangid,getsystemdefaultlcid,'+
//    'getsystemdefaultuilanguage,getsystemdirectory,getsystemfilecachesize,getsystemfirmwaretable,'+
//    'getsysteminfo,getsystemmenu,getsystemmetrics,getsystempaletteentries,getsystempaletteuse,'+
//    'getsystempowerstatus,getsystemregistryquota,getsystemtime,getsystemtimes,'+
//    'getsystemtimeadjustment,getsystemtimeasfiletime,getsystemwindowsdirectory,'+
//    'getsystemwow64directory,gettabbedtextextent,gettapeparameters,gettapeposition,'+
//    'gettapestatus,gettempfilename,gettemppath,gettextalign,gettextcharacterextra,gettextcolor,'+
//    'gettextextentexpoint,gettextextentexpointi,gettextextentpoint,gettextextentpoint32,'+
//    'gettextextentpointi,gettextface,gettextmetrics,getthreadcontext,getthreaddesktop,'+
//    'getthreadid,getthreadiopendingflag,getthreadlocale,getthreadpreferreduilanguages,'+
//    'getthreadpriority,getthreadpriorityboost,getthreadselectorentry,getthreadtimes,'+
//    'getthreaduilanguage,getthreadwaitchain,gettickcount,gettickcount64,gettimeformat,'+
//    'gettimeformatex,gettimesysinfo,gettimezoneinformation,gettitlebarinfo,gettopwindow,'+
//    'gettraceenableflags,gettraceenablelevel,gettraceloggerhandle,getupdaterect,'+
//    'getupdatergn,getuserdefaultlangid,getuserdefaultlcid,getuserdefaultuilanguage,'+
//    'getusergeoid,getusername,getusernameex,getuserobjectinformation,getversion,'+
//    'getversionex,getviewportextex,getviewportorgex,getvolumeinformation,'+
//    'getvolumenameforvolumemountpoint,getvolumepathname,getvolumepathnamesforvolumename,'+
//    'getvolumesfromdrive,getwindow,getwindowdc,getwindowextex,getwindowinfo,getwindowlong,'+
//    'getwindowlongptr,getwindowmodulefilename,getwindoworgex,getwindowplacement,'+
//    'getwindowrect,getwindowrgn,getwindowrgnbox,getwindowsdirectory,getwindowtext,'+
//    'getwindowtextlength,getwindowthreadprocessid,getwinmetafilebits,getworldtransform,'+
//    'getwritewatch,getwschanges,globaladdatom,globalalloc,globaldeleteatom,globaldiscard,'+
//    'globalfindatom,globalflags,globalfreeglobalgetatomname,globalhandle,globallock,'+
//    'globalmemorystatus,globalmemorystatusex,globalrealloc,globalsize,globalunlock,'+
//    'gradientfill,graystring,handler,handlerex,handlerroutine,heap32first,heap32listfirst,'+
//    'heap32listnext,heap32next,heapalloc,heapcompact,heapcreate,heapdestroy,heapfree,'+
//    'heaplock,heapqueryinformation,heaprealloc,heapsetinformation,heapsize,heapunlock,'+
//    'heapvalidate,heapwalk,hidecaret,hilitemenuitem,identifyntmsslot,'+
//    'impersonateddeclientwindow,importntmsdatabase,inflaterect,initatomtable,'+
//    'initializeconditionvariable,initializecriticalsection,initializecriticalsectionex,'+
//    'initializecriticalsectionandspincount,initializeprocessforwswatch,'+
//    'initializeprocthreadattributelist,initializesrwlock,initializethreadpoolenvironment,'+
//    'initiateshutdown,initiatesystemshutdown,initiatesystemshutdownex,initoncebegininitialize,'+
//    'initoncecomplete,initonceexecuteonce,initonceinitialize,injectntmscleaner,injectntmsmedia,'+
//    'insendmessage,insendmessageex,insertmenu,insertmenuitem,interlockedcompareexchange,'+
//    'interlockedcompareexchangeacquire,interlockedcompareexchangeacquire64,'+
//    'interlockedcompareexchangepointer,interlockedcompareexchangerelease,'+
//    'interlockedcompareexchangerelease64,interlockeddecrement,interlockeddecrement64,'+
//    'interlockeddecrementacquire,interlockeddecrementrelease,interlockedexchange,'+
//    'interlockedexchangeacquire64,interlockedexchangeadd,interlockedexchangepointer,'+
//    'interlockedincrement,interlockedincrement64,interlockedincrementacquire,'+
//    'interlockedincrementrelease,internalgetwindowtext,intersectcliprect,intersectrect,'+
//    'invalidaterect,invalidatergn,inventoryntmslibrary,invertrect,invertrgn,isbadcodeptr,'+
//    'isbadreadptr,isbadstringptr,isbadwriteptr,ischaralpha,ischaralphanumeric,ischarlower,'+
//    'ischarupper,ischild,isclipboardformatavailable,isdebuggerpresent,isdlgbuttonchecked,'+
//    'isguithread,ishungappwindow,isiconic,ismenu,isprocessinjob,isprocessorfeaturepresent,'+
//    'ispwrhibernateallowed,ispwrshutdownallowed,ispwrsuspendallowed,isrectempty,'+
//    'issystemresumeautomatic,isthreadafiber,isthreadpooltimerset,isvalidcodepage,'+
//    'isvalidlanguagegroup,isvalidlocale,isvalidlocalename,iswindow,iswindowenabled,'+
//    'iswindowunicode,iswindowvisible,iswow64message,iswow64process,iszoomed,journalplaybackproc,'+
//    'journalrecordproc,keybd_event,keyboardproc,killtimer,lcmapstring,leavecriticalsection,'+
//    'leavecriticalsectionwhencallbackreturns,linedda,lineddaproc,lineto,loadaccelerators,'+
//    'loadbitmap,loadcursor,loadcursorfromfile,loadicon,loadimage,loadkeyboardlayout,'+
//    'loadlibrary,loadlibraryex,loadmenu,loadmenuindirect,loadmodule,loadperfcountertextstrings,'+
//    'loadresource,loadstring,localalloc,localdiscard,localfiletimetofiletime,localflags,'+
//    'localfree,localhandle,locallock,localrealloc,localsize,localunlock,lockfile,'+
//    'lockfileex,lockresource,lockservicedatabase,locksetforegroundwindow,lockwindowupdate,'+
//    'lockworkstation,logicaltophysicalpoint,logtimeprovevent,lookupiconidfromdirectory,'+
//    'lookupiconidfromdirectoryex,lowlevelkeyboardproc,lowlevelmouseproc,lptodp,lstrcat,'+
//    'lstrcmp,lstrcmpi,lstrcpy,lstrcpyn,lstrlen,lzclose,lzcopy,lzinit,lzopenfile,lzread,'+
//    'lzseek,mapdialogrect,mapuserphysicalpages,mapuserphysicalpagesscatter,mapviewoffile,'+
//    'mapviewoffileex,mapviewoffileexnuma,mapvirtualkey,mapvirtualkeyex,mapwindowpoints,'+
//    'maskblt,maxmedialabel,memorybarrier,menuitemfrompoint,messagebeep,messagebox,'+
//    'messageboxex,messageboxindirect,messageproc,modifymenu,modifyworldtransform,module32first,'+
//    'module32next,monitorenumproc,monitorfrompoint,monitorfromrect,monitorfromwindow,'+
//    'mountntmsmedia,mouse_event,mouseproc,movefile,movefileex,movefilewithprogress,'+
//    'movememory,movetoex,movetontmsmediapool,movewindow,msgwaitformultipleobjects,'+
//    'msgwaitformultipleobjectsex,multinetgetconnectionperformance,nddegeterrorstring,'+
//    'nddegetsharesecurity,nddegettrustedshare,nddeisvalidapptopiclist,nddeisvalidsharename,'+
//    'nddesetsharesecurity,nddesettrustedshare,nddeshareadd,nddesharedel,nddeshareenum,'+
//    'nddesharegetinfo,nddesharesetinfo,nddetrustedshareenum,netaccessadd,netaccesscheck,'+
//    'netaccessdel,netaccessenum,netaccessgetinfo,netaccessgetuserperms,netaccesssetinfo,'+
//    'netalertraise,netalertraiseex,netapibufferallocate,netapibufferfree,'+
//    'netapibufferreallocate,netapibuffersize,netauditclear,netauditread,netauditwrite,'+
//    'netconfigget,netconfiggetall,netconfigset,netconnectionenum,netdfsadd,netdfsaddftroot,'+
//    'netdfsaddstdroot,netdfsaddstdrootforced,netdfsenum,netdfsgetclientinfo,netdfsgetinfo,'+
//    'netdfsmanagerinitialize,netdfsremove,netdfsremoveftroot,netdfsremoveftrootforced,'+
//    'netdfsremovestdroot,netdfssetclientinfo,netdfssetinfo,neterrorlogclear,neterrorlogread,'+
//    'neterrorlogwrite,netfileclose,netfileenum,netfilegetinfo,netgetanydcname,netgetdcname,'+
//    'netgetdisplayinformationindex,netgetjoinableous,netgetjoininformation,netgroupadd,'+
//    'netgroupadduser,netgroupdel,netgroupdeluser,netgroupenum,netgroupgetinfo,netgroupgetusers,'+
//    'netgroupsetinfo,netgroupsetusers,netjoindomain,netlocalgroupadd,netlocalgroupaddmember,'+
//    'netlocalgroupaddmembers,netlocalgroupdel,netlocalgroupdelmember,netlocalgroupdelmembers,'+
//    'netlocalgroupenum,netlocalgroupgetinfo,netlocalgroupgetmembers,netlocalgroupsetinfo,'+
//    'netlocalgroupsetmembers,netmessagebuffersend,netmessagenameadd,netmessagenamedel,'+
//    'netmessagenameenum,netmessagenamegetinfo,netquerydisplayinformation,'+
//    'netremotecomputersupports,netremotetod,netrenamemachineindomain,netschedulejobadd,'+
//    'netschedulejobdel,netschedulejobenum,netschedulejobgetinfo,netservercomputernameadd,'+
//    'netservercomputernamedel,netserverdiskenum,netserverenum,netservergetinfo,'+
//    'netserversetinfo,netservertransportadd,netservertransportaddex,netservertransportdel,'+
//    'netservertransportenum,netservicecontrol,netserviceenum,netservicegetinfo,netserviceinstall,'+
//    'netsessiondel,netsessionenum,netsessiongetinfo,netshareadd,netsharecheck,'+
//    'netsharedel,netshareenum,netsharegetinfo,netsharesetinfo,netstatisticsget,netunjoindomain,'+
//    'netuseadd,netusedel,netuseenum,netusegetinfo,netuseradd,netuserchangepassword,'+
//    'netuserdel,netuserenum,netusergetgroups,netusergetinfo,netusergetlocalgroups,'+
//    'netusermodalsget,netusermodalsset,netusersetgroups,netusersetinfo,netvalidatename,'+
//    'netwkstagetinfo,netwkstasetinfo,netwkstatransportadd,netwkstatransportdel,'+
//    'netwkstatransportenum,netwkstauserenum,netwkstausergetinfo,netwkstausersetinfo,'+
//    'notifybootconfigstatus,notifychangeeventlog,notifyservicestatuschange,'+
//    'oemkeyscan,oemtochar,oemtocharbuff,offsetcliprgn,offsetrect,offsetrgn,offsetviewportorgex,'+
//    'offsetwindoworgex,openbackupeventlog,openclipboard,opendesktop,openevent,'+
//    'openeventlog,openfile,openfilebyid,openfilemapping,openicon,openinputdesktop,'+
//    'openjobobject,openmutex,openntmsnotification,openntmssession,openprinter,'+
//    'openprivatenamespace,openprocess,openscmanager,opensemaphore,openservice,'+
//    'openthread,openthreadwaitchainsession,opentrace,openwaitabletimer,openwindowstation,'+
//    'outputdebugstring,packddelparam,paintdesktop,paintrgn,patblt,pathtoregion,pdhaddcounter,'+
//    'pdhaddenglishcounter,pdhbindinputdatasource,pdhbrowsecounters,pdhbrowsecountersh,'+
//    'pdhcalculatecounterfromrawvalue,pdhcloselog,pdhclosequery,pdhcollectquerydata,'+
//    'pdhcollectquerydataex,pdhcollectquerydatawithtime,pdhcomputecounterstatistics,'+
//    'pdhconnectmachine,pdhenumlogsetnames,pdhenummachines,pdhenummachinesh,'+
//    'pdhenumobjectitems,pdhenumobjectitemsh,pdhenumobjects,pdhenumobjectsh,'+
//    'pdhexpandcounterpath,pdhexpandwildcardpath,pdhexpandwildcardpathh,pdhformatfromrawvalue,'+
//    'pdhgetcounterinfo,pdhgetcountertimebase,pdhgetdatasourcetimerange,pdhgetdatasourcetimerangeh,'+
//    'pdhgetdefaultperfcounter,pdhgetdefaultperfcounterh,pdhgetdefaultperfobject,'+
//    'pdhgetdefaultperfobjecth,pdhgetdllversion,pdhgetformattedcounterarray,'+
//    'pdhgetformattedcountervalue,pdhgetlogfilesize,pdhgetrawcounterarray,'+
//    'pdhgetrawcountervalue,pdhisrealtimequery,pdhlookupperfindexbyname,pdhlookupperfnamebyindex,'+
//    'pdhmakecounterpath,pdhopenlog,pdhopenquery,pdhopenqueryh,pdhparsecounterpath,'+
//    'pdhparseinstancename,pdhreadrawlogrecord,pdhremovecounter,pdhselectdatasource,'+
//    'pdhsetcounterscalefactor,pdhsetdefaultrealtimedatasource,pdhsetquerytimerange,'+
//    'pdhupdatelog,pdhupdatelogfilecatalog,pdhvalidatepath,pdhvalidatepathex,'+
//    'peekconsoleinput,peekmessage,peeknamedpipe,physicaltologicalpoint,pie,playenhmetafile,'+
//    'playenhmetafilerecord,playmetafile,playmetafilerecord,plgblt,polybezier,polybezierto,'+
//    'polydraw,polygon,polyline,polylineto,polypolygon,polypolyline,polytextout,postmessage,'+
//    'postqueuedcompletionstatus,postquitmessage,postthreadmessage,prefetchcacheline,'+
//    'preparetape,printdlg,printdlgex,printerproperties,printwindow,privateextracticons,'+
//    'process32first,process32next,processtrace,propenumproc,propenumprocex,ptinrect,'+
//    'ptinregion,ptvisible,pulseevent,purgecomm,queryalltraces,querydepthslist,+querydosdevice,'+
//    'queryfullprocessimagename,queryidleprocessorcycletime,queryinformationjobobject,'+
//    'queryperformancecounter,queryperformancefrequency,queryprocesscycletime,'+
//    'queryrecoveryagentsonencryptedfile,queryserviceconfig,queryserviceconfig2,'+
//    'queryservicelockstatus,queryservicestatus,queryservicestatusex,querythreadcycletime,'+
//    'querytrace,queryusersonencryptedfile,queryworkingset,queryworkingsetex,queueuserapc,'+
//    'queueuserworkitem,raiseexception,readconsole,readconsoleinput,readconsoleoutput,'+
//    'readconsoleoutputattribute,readconsoleoutputcharacter,readdirectorychangesw,readeventlog,'+
//    'readfile,readfileex,readfilescatter,readglobalpwrpolicy,readprinter,readprocessmemory,'+
//    'readprocessorpwrscheme,readpwrscheme,realchildwindowfrompoint,realgetwindowclass,'+
//    'realizepalette,rectangle,rectinregion,rectvisible,redrawwindow,regclosekey,'+
//    'regconnectregistry,regcopytree,regcreatekey,regcreatekeyex,regcreatekeytransacted,'+
//    'regdeletekey,regdeletekeyex,regdeletekeytransacted,regdeletekeyvalue,regdeletetree,'+
//    'regdeletevalue,regdisablepredefinedcache,regdisablepredefinedcacheex,'+
//    'regdisablereflectionkey,regenablereflectionkey,regenumkey,regenumkeyex,regenumvalue,'+
//    'regflushkey,reggetvalue,registerapplicationrecoverycallback,registerapplicationrestart,'+
//    'registerclass,registerclassex,registerclipboardformat,registerdevicenotification,'+
//    'registereventsource,registerhotkey,registerpowersettingnotification,registerrawinputdevices,'+
//    'registerservicectrlhandler,registerservicectrlhandlerex,registershellhookwindow,'+
//    'registertraceguids,registerwaitchaincomcallback,registerwaitforsingleobject,'+
//    'registerwindowmessage,regloadappkey,regloadkey,regloadmuistring,regnotifychangekeyvalue,'+
//    'regopencurrentuser,regopenkey,regopenkeyex,regopenkeytransacted,regopenuserclassesroot,'+
//    'regoverridepredefkey,regqueryinfokey,regquerymultiplevalues,regqueryreflectionkey,'+
//    'regqueryvalue,regqueryvalueex,regreplacekey,regrestorekey,regsavekeyregsavekeyex,'+
//    'regsetkeyvalue,regsetvalue,regsetvalueex,regunloadkey,releasecapture,releasedc,'+
//    'releasemutex,releasemutexwhencallbackreturns,releasentmscleanerslot,releasesemaphore,'+
//    'releasesemaphorewhencallbackreturns,releasesrwlockexclusive,releasesrwlockshared,'+
//    'removedirectory,removefontmemresourceex,removefontresource,removefontresourceex,'+
//    'removemenu,removeprop,removetracecallback,removeusersfromencryptedfile,'+
//    'removevectoredexceptionhandler,reopenfile,replacefile,replymessage,reportevent,'+
//    'reportfault,requestwakeuplatency,reserventmscleanerslot,resetdc,resetevent,resetprinter,'+
//    'resetwritewatch,resizepalette,restoredc,resumethread,reuseddelparam,rmaddfilter,'+
//    'rmcancelcurrenttask,rmendsession,rmgetfilterlist,rmgetlist,rmjoinsession,'+
//    'rmregisterresources,rmremovefilter,rmrestart,rmshutdown,rmstartsession,roundrect,'+
//    'satisfyntmsoperatorrequest,savedc,scaleviewportextex,scalewindowextex,schedulejob,'+
//    'screentoclient,scrollconsolescreenbuffer,scrolldc,scrollwindow,scrollwindowex,'+
//    'searchpath,securezeromemory,selectclippath,selectcliprgn,selectobject,selectpalette,'+
//    'sendasyncproc,senddlgitemmessage,sendinput,sendmessage,sendmessagecallback,'+
//    'sendmessagetimeout,sendnotifymessage,servicemain,setabortproc,setactivepwrscheme,'+
//    'setactivewindow,setarcdirection,setbitmapbits,setbitmapdimensionex,setbkcolor,'+
//    'setbkmode,setboundsrect,setbrushorgex,setcalendarinfo,setcapture,setcaretblinktime,'+
//    'setcaretpos,setclasslong,setclasslongptr,setclassword,setclipboarddata,setclipboardviewer,'+
//    'setcoloradjustment,setcommbreak,setcommconfig,setcommmask,setcommstate,setcommtimeouts,'+
//    'setcomputername,setcomputernameex,setconsoleactivescreenbuffer,setconsolecp,'+
//    'setconsolectrlhandler,setconsolecursorinfo,setconsolecursorposition,setconsolehistoryinfo,'+
//    'setconsolemode,setconsoleoutputcp,setconsolescreenbufferinfoex,setconsolescreenbuffersize,'+
//    'setconsoletextattribute,setconsoletitle,setconsolewindowinfo,setcriticalsectionspincount,'+
//    'setcurrentconsolefontex,setcurrentdirectory,setcursor,setcursorpos,setdcbrushcolor,'+
//    'setdcpencolor,setdefaultcommconfig,setdefaultprinter,setdibcolortable,setdibits,'+
//    'setdibitstodevice,setdlgitemint,setdlgitemtext,setdlldirectory,setdoubleclicktime,'+
//    'setdynamictimezoneinformation,setendoffile,setenhmetafilebits,setenvironmentvariable,'+
//    'seterrormode,setevent,seteventwhencallbackreturns,setfileapistoansi,setfileapistooem,'+
//    'setfileattributes,setfilebandwidthreservation,setfilecompletionnotificationmodes,'+
//    'setfileinformationbyhandle,setfileiooverlappedrange,setfilepointer,setfilepointerex,'+
//    'setfileshortname,setfiletime,setfilevaliddata,setfocus,setforegroundwindow,setform,'+
//    'setgraphicsmode,setinformationjobobject,setjob,setkeyboardstate,setlasterror,'+
//    'setlasterrorex,setlayeredwindowattributes,setlayout,setlocaleinfo,setlocaltime,'+
//    'setmailslotinfo,setmapmode,setmapperflags,setmenu,setmenudefaultitem,setmenuinfo,'+
//    'setmenuitembitmaps,setmenuiteminfo,setmessageextrainfo,setmetafilebitsex,setmetargn,'+
//    'setmiterlimit,setnamedpipehandlestate,setntmsdevicechangedetection,setntmsmediacomplete,'+
//    'setntmsobjectattribute,setntmsobjectinformation,setntmsobjectsecurity,setntmsrequestorder,'+
//    'setntmsuioptions,setpaletteentries,setparent,setphysicalcursorpos,setpixel,setpixelv,'+
//    'setpolyfillmode,setport,setprinter,setprinterdata,setprinterdataex,setpriorityclass,'+
//    'setprocessaffinitymask,setprocessdefaultlayout,setprocesspriorityboost,'+
//    'setprocessshutdownparameters,setprocesswindowstation,setprocessworkingsetsize,'+
//    'setprocessworkingsetsizeex,setprop,setproviderstatusfunc,setproviderstatusinfofreefunc,'+
//    'setrect,setrectempty,setrectrgn,setrop2,setscrollinfo,setscrollpos,setscrollrange,'+
//    'setservicebits,setservicestatus,setstdhandle,setstretchbltmode,setsuspendstate,setsyscolors,'+
//    'setsystemcursor,setsystemfilecachesize,setsystempaletteuse,setsystempowerstate,'+
//    'setsystemtime,setsystemtimeadjustment,settapeparameters,settapeposition,'+
//    'settextalign,settextcharacterextra,settextcolor,settextjustification,setthreadaffinitymask,'+
//    'setthreadcontext,setthreaddesktop,setthreadexecutionstate,setthreadidealprocessor,'+
//    'setthreadlocale,setthreadpoolcallbackcleanupgroup,setthreadpoolcallbacklibrary,'+
//    'setthreadpoolcallbackpool,setthreadpoolcallbackrunslong,setthreadpoolthreadmaximum,'+
//    'setthreadpoolthreadminimum,setthreadpooltimer,setthreadpoolwait,setthreadpriority,'+
//    'setthreadpriorityboost,setthreadstackguarantee,settimer,settimezoneinformation,'+
//    'settracecallback,setunhandledexceptionfilter,setupcomm,setuserfileencryptionkey,'+
//    'setusergeoid,setuserobjectinformation,setviewportextex,setviewportorgex,'+
//    'setvolumelabel,setvolumemountpoint,setwaitabletimer,setwindowextex,setwindowlong,'+
//    'setwindowlongptr,setwindoworgex,setwindowplacement,setwindowpos,setwindowrgn,'+
//    'setwindowshookex,setwindowtext,setwinmetafilebits,setworldtransform,'+
//    'shadddefaultpropertiesbyext,shaddtorecentdocs,shappbarmessage,shassocenumhandlers,'+
//    'shbindtofolderidlistparent,shbindtofolderidlistparentex,shbindtoobject,'+
//    'shbindtoparent,shbrowseforfolder,shchangenotify,shchangenotifyregisterthread,'+
//    'shcreateassociationregistration,shcreatedataobject,shcreatedefaultcontextmenu,'+
//    'shcreatedefaultextracticon,shcreatedefaultpropertiesop,shcreatedirectory,'+
//    'shcreatedirectoryex,shcreateitemfromidlist,shcreateitemfromparsingname,'+
//    'shcreateitemfromrelativename,shcreateiteminknownfolder,shcreateitemwithparent,'+
//    'shcreateprocessasuserw,shcreateshellfolderview,shcreateshellfolderviewex,'+
//    'shcreateshellitem,shcreateshellitemarray,shcreateshellitemarrayfromdataobject,'+
//    'shcreateshellitemarrayfromidlists,shcreateshellitemarrayfromshellitem,'+
//    'shdodragdrop,shellabout,shellexecute,shellexecuteex,shemptyrecyclebin,'+
//    'shenumerateunreadmailaccounts,shevaluatesystemcommandtemplate,shfileoperation,'+
//    'shformatdrive,shfreenamemappings,shgetdatafromidlist,shgetdesktopfolder,'+
//    'shgetdiskfreespace,shgetdiskfreespaceex,shgetdrivemedia,shgetfileinfo,shgetfolderlocation,'+
//    'shgetfolderpath,shgetfolderpathandsubdir,shgeticonoverlayindex,shgetidlistfromobject,'+
//    'shgetimagelist,shgetinstanceexplorer,shgetknownfolderidlist,shgetknownfolderpath,'+
//    'shgetlocalizedname,shgetnamefromidlist,shgetnamefrompropertykey,shgetnewlinkinfo,'+
//    'shgetpathfromidlist,shgetpathfromidlistex,shgetpropertystorefromidlist,'+
//    'shgetpropertystorefromparsingname,shgetsettings,shgetspecialfolderlocation,'+
//    'shgetspecialfolderpath,shgetstockiconinfo,shgettemporarypropertyforitem,'+
//    'shgetunreadmailcount,shinvokeprintercommand,shisfileavailableoffline,'+
//    'shloadnonloadediconoverlayidentifiers,shlocalstrdup,shopenfolderandselectitems,'+
//    'shopenwithdialog,showcaret,showcursor,showownedpopups,showscrollbar,showwindow,'+
//    'showwindowasync,shparsedisplayname,shpathprepareforwrite,shqueryrecyclebin,'+
//    'shqueryusernotificationstate,shreggetboolvaluefromhkcuhklm,shreggetvaluefromhkcuhklm,'+
//    'shremovelocalizedname,shsetdefaultproperties,shsetfolderpath,shsetknownfolderpath,'+
//    'shsetlocalizedname,shsettemporarypropertyforitem,shsetunreadmailcount,shtesttokenmembership,'+
//    'shupdateimage,shutdownblockreasoncreate,shutdownblockreasondestroy,shutdownblockreasonquery,'+
//    'signalobjectandwait,siscreatebackupstructure,siscreaterestorestructure,'+
//    'siscsfilestobackupforlink,sisfreeallocatedmemory,sisfreebackupstructure,'+
//    'sisfreerestorestructure,sisrestoredcommonstorefile,sisrestoredlink,sizeofresource,'+
//    'sleep,sleepconditionvariablecs,sleepconditionvariablesrw,sleepex,startdoc,startdocprinter,'+
//    'startpage,startpageprinter,startservice,startservicectrldispatcher,startthreadpoolio,'+
//    'starttrace,stoptrace,stretchblt,stretchdibits,stringcbcat,stringcbcatex,stringcbcatn,'+
//    'stringcbcatnex,stringcbcopy,stringcbcopyex,stringcbcopyn,stringcbcopynex,stringcbgets,'+
//    'stringcbgetsex,stringcblength,stringcbprintf,stringcbprintfex,stringcbvprintf,'+
//    'stringcbvprintfex,stringcchcat,stringcchcatex,stringcchcatn,stringcchcatnex,'+
//    'stringcchcopy,stringcchcopyex,stringcchcopyn,stringcchcopynex,stringcchgets,'+
//    'stringcchgetsex,stringcchlength,stringcchprintf,stringcchprintfex,stringcchvprintf,'+
//    'stringcchvprintfex,strokeandfillpath,strokepath,submitntmsoperatorrequest,'+
//    'submitthreadpoolwork,subtractrect,suspendthread,swapmousebutton,swapntmsmedia,'+
//    'switchdesktop,switchtofiber,switchtothiswindow,switchtothread,sysmsgproc,'+
//    'systemparametersinfo,systemtimetofiletime,systemtimetotzspecificlocaltime,'+
//    'tabbedtextout,taskdialog,taskdialogindirect,terminatejobobject,terminateprocess,'+
//    'terminatethread,textout,thread32first,thread32next,threadproc,tilewindows,'+
//    'timeprovclose,timeprovcommand,timeprovopen,timerapcproc,timerproc,tlsalloc,'+
//    'tlsfree,tlsgetvalue,tlssetvalue,toascii,toasciiex,toolhelp32readprocessmemory,'+
//    'tounicode,tounicodeex,traceevent,traceeventinstance,tracemessage,tracemessageva,'+
//    'trackmouseevent,trackpopupmenu,trackpopupmenuex,transactnamedpipe,translateaccelerator,'+
//    'translatemdisysaccel,translatemessage,translatename,transmitcommchar,transparentblt,'+
//    'tryentercriticalsection,trysubmitthreadpoolcallback,tzspecificlocaltimetosystemtime,'+
//    'unhandledexceptionfilter,unhookwindowshookex,unionrect,unloadkeyboardlayout,'+
//    'unloadperfcountertextstrings,unlockfile,unlockfileex,unlockservicedatabase,'+
//    'unmapviewoffile,unpackddelparam,unrealizeobject,unregisterapplicationrecoverycallback,'+
//    'unregisterapplicationrestart,unregisterclass,unregisterdevicenotification,'+
//    'unregisterhotkey,unregisterpowersettingnotification,unregistertraceguids,'+
//    'unregisterwait,unregisterwaitex,updatecolors,updatelayeredwindow,updatentmsomidinfo,'+
//    'updateprocthreadattribute,updateresource,updatetrace,updatewindow,userhandlegrantaccess,'+
//    'validaterect,validatergn,vectoredhandler,verfindfile,verifyversioninfo,verinstallfile,'+
//    'verlanguagename,verqueryvalue,versetconditionmask,virtualalloc,virtualallocex,'+
//    'virtualallocexnuma,virtualfree,virtualfreeex,virtuallock,virtualprotect,virtualprotectex,'+
//    'virtualquery,virtualqueryex,virtualunlock,vkkeyscan,vkkeyscanex,waitcommevent,'+
//    'waitfordebugevent,waitforinputidle,waitformultipleobjects,waitformultipleobjectsex,'+
//    'waitforntmsnotification,waitforntmsoperatorrequest,waitforsingleobject,'+
//    'waitforsingleobjectex,waitforthreadpooliocallbacks,waitforthreadpooltimercallbacks,'+
//    'waitforthreadpoolwaitcallbacks,waitforthreadpoolworkcallbacks,waitmessage,'+
//    'waitnamedpipe,waitortimercallback,wakeallconditionvariable,wakeconditionvariable,'+
//    'weraddexcludedapplication,wergetflags,werregisterfile,werregistermemoryblock,'+
//    'werremoveexcludedapplication,werreportadddump,werreportaddfile,werreportclosehandle,'+
//    'werreportcreate,werreportsetparameter,werreportsetuioption,werreportsubmit,'+
//    'wersetflags,werunregisterfile,werunregistermemoryblock,widenpath,windowfromdc,'+
//    'windowfrompoint,windowproc,winexec,winmain,wnetaddconnection,wnetaddconnection2,'+
//    'wnetaddconnection3,wnetcancelconnection,wnetcancelconnection2,wnetcloseenum,'+
//    'wnetconnectiondialog,wnetconnectiondialog1,wnetdisconnectdialog,wnetdisconnectdialog1,'+
//    'wnetenumresource,wnetgetconnection,wnetgetlasterror,wnetgetnetworkinformation,'+
//    'wnetgetprovidername,wnetgetresourceinformation,wnetgetresourceparent,wnetgetuniversalname,'+
//    'wnetgetuser,wnetopenenum,wnetuseconnection,wow64disablewow64fsredirection,'+
//    'wow64enablewow64fsredirection,wow64getthreadcontext,wow64revertwow64fsredirection,'+
//    'wow64setthreadcontext,wow64suspendthread,writeconsole,writeconsoleinput,'+
//    'writeconsoleoutput,writeconsoleoutputattribute,writeconsoleoutputcharacter,'+
//    'writefile,writefileex,writefilegather,writeglobalpwrpolicy,writeprinter,'+
//    'writeprivateprofilesection,writeprivateprofilestring,writeprivateprofilestruct,'+
//    'writeprocessmemory,writeprocessorpwrscheme,writeprofilesection,writeprofilestring,'+
//    'writepwrscheme,writetapemark,wsprintf,wvsprintf,zeromemory';

  Directives: UnicodeString =
    '=,.386,.386p,.387,.486,.486p,.586,.586p,.686,.686p,alias,align,.allocstack,'+
    '.alpha,assume,.break,byte,catstr,.code,comm,comment,.const,.continue,.cref,'+
    '.data,.data?,db,dd,df,.dosseg,dosseg,dq,dt,dw,dword,echo,.else,else,elseif,'+
  	'.elseif,'+
    'elseif2,end,.endif,endm,endp,.endprolog,ends,.endw,equ,.err,.err2,.errb,'+
    '.errdef,.errdif[[i]],.erre,.erridn[[i]],.errnb,.errndef,.errnz,even,.exit,'+
    'exitm,extern,externdef,extrn,.fardata,.fardata?,for,forc,.fpo,fword,goto,'+
    'group,.if,if,if2,ifb,ifdef,ifdif[[i]],ife,ifidn[[i]],ifnb,ifndef,include,'+
    'includelib,instr,invoke,irp,irpc,.k3d,label,.lall,.lfcond,.list,.listall,'+
    '.listif,.listmacro,.listmacroall,local,macro,mmword,.mmx,.model,name,'+
    '.nocref,.nollist,.nolistif,.nolistmacro,offset,option,org,%out,oword,page,'+
    'popcontext,proc,proto,public,purge,pushcontext,.pushframe,.pushreg,qword,'+
    '.radix,real10,real4,real8,record,.repeat,repeat,rept,.safeseh,.sall,'+
    '.savereg,.savexmm128,sbyte,sdword,segment,.seq,.setframe,.sfcond,sizestr,'+
    'sqword,.stack,.startup,struc,struct,substr,subtitle,subttl,sword,tbyte,'+
    'textequ,.tfcond,title,typedef,union,.until,.untilcxz,.while,while,word,'+
    '.xall,.xcref,.xlist,.xmm,xmmword,ymmword,'+
    'tiny,small,compact,medium,large,huge,flat,nearstack,farstack'; // .MODEL options

  // Directives for Masm and Tasm
//  ProcessorSpecification: UnicodeString =
//    '.186,.286,.286C,.286P,.287,.386,.386C,.386P,.387,' +
//    '.486,.486C,.486P,.586,.8086,.8087,.NO87,P186,P286,P286N,P286P,P287,P386,P386N,' +
//    'P386P,P387,P486,P486N,P8086,P8087,PNO87';
//
//  GlobalControl: UnicodeString =
//    'align,emul,ideal,jumps,largestack,masm,masm51,.msfloat,' +
//    'multerrs,name,noemul,nojumps,nomasm51,nomulterrs,nosmart,nowarn,option,popcontext,' +
//    'pushcontext,quirks,.radix,radix,smallstack,smart,version,warn';
//
//  SegmentControl: UnicodeString =
//    '.alpha,alpha,assume,.code,codeseg,.const,const,.data,.data?,' +
//    'dataseg,.dosseg,end,ends,.exit,exitcode,.fardata,fardata,.fardata?,group,.model,' +
//    'model,org,segment,.seq,seq,.stack,stack,.startup,startupcode,udataseg,ufardata';
//
//  Procedures: UnicodeString =
//    'arg,endp,invoke,label,local,locals,nolocals,proc,proto,uses';
//
//  Scope: UnicodeString =
//    'comm,extern.externdef,extrn,global,include,includelib,publicdll,public';
//
//  DataAllocation: UnicodeString =
//    'byte,db,dd,df,dp,dt,dw,dword,dq,fword,qword,real4,real8,' +
//    'real10,sbyte,sdword,sword,tbyte,word';
//
//  ComplexDataTypes: UnicodeString =
//    'align,ends,enum,even,evendata,record,struc,struct,table,' +
//    'tblptr,typedef,union';
//
//  Macros: UnicodeString =
//    'endm,exitm,for,forc,goto,irp,irpc,macro,purge,repeat,rept,textequ,while';
//
//  ConditionalAssembly: UnicodeString =
//    'else,elseif,endif,if,if1,if2,ifb,ifdef,ifdif,ifdif1,ife,' +
//    'ifidn,ifidni,ifnb,ifndef';
//
//  ConditionalError: UnicodeString =
//    '.err,err,.err1,.err2,.errb,.errdef,.errdif,.errdifi,.erredifni'+
//    'errif,errif1,errif2,errifb,errifdef,errifdif,errifdifi,errife,errifidn,errifidni,' +
//    'errifnn,errifndef,.errnb,.errndef,.errnz';
//
//  ListingControl: UnicodeString =
//    '%bin,%conds,%cref,.cref,%crefall,%crefref,%crefuref,%ctls,%depth,' +
//    '%incl,.lall,.lfcond,%linum,%list,.list,.listall,.listif,.listmacro,.listmacroall,%macs,' +
//    '%newpage,%noconds,%nocref,.nocref,%noctls,%noincl,%nolist,.nolist,.nolistif,.nolistmacro,' +
//    '%nomacs,%nosyms,%notrunc,page,$pagesize,%pcnt,%poplctl,%pushlctl,.sall,.sfcond,subtitle,' +
//    '%subttl,subttl,$syms,%tablsize,%text,.tfcond,%title,title,%trunc,.xall,.xcref,.xlist';
//
//  StringControl: UnicodeString = 'catstr,instr,sizestr,substr';
//
//  Miscellaneous: UnicodeString = '=,comment,display,echo,equ,%out';

procedure TSynAsmMASMSyn.DoAddKeyword(AKeyword: UnicodeString; AKind: integer);
var
  HashValue: Cardinal;
begin
  HashValue := HashKey(PWideChar(AKeyword));
  fKeywords[HashValue] := TSynHashEntry.Create(AKeyword, AKind);
end;

procedure TSynAsmMASMSyn.DoAddDirectivesKeyword(AKeyword: UnicodeString; AKind: integer);
var
  HashValue: Cardinal;
begin
  HashValue := HashKey(PWideChar(AKeyword));
  fDirectivesKeywords[HashValue] := TSynHashEntry.Create(AKeyword, AKind);
end;

procedure TSynAsmMASMSyn.DoAddRegisterKeyword(AKeyword: UnicodeString; AKind: integer);
var
  HashValue: Cardinal;
begin
  HashValue := HashKey(PWideChar(AKeyword));
  fRegisterKeywords[HashValue] := TSynHashEntry.Create(AKeyword, AKind);
end;

procedure TSynAsmMASMSyn.DoAddApiKeyword(AKeyword: UnicodeString; AKind: integer);
var
  HashValue: Cardinal;
begin
  HashValue := HashKey(PWideChar(AKeyword));
  fApiKeywords[HashValue] := TSynHashEntry.Create(AKeyword, AKind);
end;

//{$Q-}
function TSynAsmMASMSyn.HashKey(Str: PWideChar): Cardinal;
begin
  Result := 0;
  while IsIdentChar(Str^) do
  begin
    Result := Result * 197 + Ord(Str^) * 14;
    inc(Str);
  end;
  Result := Result mod 4561;
  fStringLen := Str - fToIdent;
end;
//{$Q+}

//function SuperFastHash(AData:pointer; ADataLength: integer):longword;
//// Pascal translation of the SuperFastHash function by Paul Hsieh
//// more info: http://www.azillionmonkeys.com/qed/hash.html
//// Translation by: Davy Landman
//// No warranties, but have fun :)
//var
//  TempPart: longword;
//  RemainingBytes: integer;
//begin
//  if not Assigned(AData) or (ADataLength <= 0) then
//  begin
//    Result := 0;
//    Exit;
//  end;
//  Result := ADataLength;
//  RemainingBytes := ADataLength and 3;
//  ADataLength := ADataLength shr 2; // div 4, so var name is not correct anymore..
//  // main loop
//  while ADataLength > 0 do
//  begin
//    inc(Result, PWord(AData)^);
//    TempPart := (PWord(Pointer(Cardinal(AData)+2))^ shl 11) xor Result;
//    Result := (Result shl 16) xor TempPart;
//    AData := Pointer(Cardinal(AData) + 4);
//    inc(Result, Result shr 11);
//    dec(ADataLength);
//  end;
//  // end case
//  if RemainingBytes = 3 then
//  begin
//    inc(Result, PWord(AData)^);
//    Result := Result xor (Result shl 16);
//    Result := Result xor (PByte(Pointer(Cardinal(AData)+2))^ shl 18);
//    inc(Result, Result shr 11);
//  end
//  else if RemainingBytes = 2 then
//  begin
//    inc(Result, PWord(AData)^);
//    Result := Result xor (Result shl 11);
//    inc(Result, Result shr 17);
//  end
//  else if RemainingBytes = 1 then
//  begin
//    inc(Result, PByte(AData)^);
//    Result := Result xor (Result shl 10);
//    inc(Result, Result shr 1);
//  end;
//  // avalance
//  Result := Result xor (Result shl 3);
//  inc(Result, Result shr 5);
//  Result := Result xor (Result shl 4);
//  inc(Result, Result shr 17);
//  Result := Result xor (Result shl 25);
//  inc(Result, Result shr 6);
//end;

//// THJ Added new hash function
//function TSynAsmMASMSyn.HashKey(Str: PWideChar): Cardinal;
//var
//  Off, Len, Skip, I: Integer;
//begin
//  Result := 0;
//  Off := 1;
//  Len := StrLen(Str);
//  if Len < 16 then
//    for I := (Len - 1) downto 0 do
//    begin
//      Result := (Result * 37) + Ord(Str[Off]);
//      Inc(Off);
//    end
//  else
//  begin
//    { Only sample some characters }
//    Skip := Len div 8;
//    I := Len - 1;
//    while I >= 0 do
//    begin
//      Result := (Result * 39) + Ord(Str[Off]);
//      Dec(I, Skip);
//      Inc(Off, Skip);
//    end;
//  end;
//end;

function TSynAsmMASMSyn.IdentKind(MayBe: PWideChar): TtkTokenKind;
var
  Entry: TSynHashEntry;
begin
  fToIdent := MayBe;
  Entry := fKeywords[HashKey(MayBe)];
  while Assigned(Entry) do
  begin
    if Entry.KeywordLen > fStringLen then
      break
    else if Entry.KeywordLen = fStringLen then
      if IsCurrentToken(Entry.Keyword) then
      begin
        Result := TtkTokenKind(Entry.Kind);
        exit;
      end;
    Entry := Entry.Next;
  end;

  // THJ
  Entry := fDirectivesKeywords[HashKey(MayBe)];
  while Assigned(Entry) do
  begin
    if Entry.KeywordLen > fStringLen then
      break
    else if Entry.KeywordLen = fStringLen then
      if IsCurrentToken(Entry.Keyword) then
      begin
        Result := TtkTokenKind(Entry.Kind);
        exit;
      end;
    Entry := Entry.Next;
  end;

  // THJ
  Entry := fRegisterKeywords[HashKey(MayBe)];
  while Assigned(Entry) do
  begin
    if Entry.KeywordLen > fStringLen then
      break
    else if Entry.KeywordLen = fStringLen then
      if IsCurrentToken(Entry.Keyword) then
      begin
        Result := TtkTokenKind(Entry.Kind);
        exit;
      end;
    Entry := Entry.Next;
  end;

  // THJ
  Entry := fApiKeywords[HashKey(MayBe)];
  while Assigned(Entry) do
  begin
    if Entry.KeywordLen > fStringLen then
      break
    else if Entry.KeywordLen = fStringLen then
      if IsCurrentToken(Entry.Keyword) then
      begin
        Result := TtkTokenKind(Entry.Kind);
        exit;
      end;
    Entry := Entry.Next;
  end;

  Result := tkIdentifier;
end;

constructor TSynAsmMASMSyn.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  fCaseSensitive := False;

  fKeywords := TSynHashEntryList.Create;
  fDirectivesKeywords := TSynHashEntryList.Create;
  fRegisterKeywords := TSynHashEntryList.Create;
  fApiKeywords := TSynHashEntryList.Create;

  fCommentAttri       := TSynHighlighterAttributes.Create(SYNS_AttrComment, SYNS_FriendlyAttrComment);
  fCommentAttri.Style := [fsItalic];
  AddAttribute(fCommentAttri);

  fIdentifierAttri    := TSynHighlighterAttributes.Create(SYNS_AttrIdentifier, SYNS_FriendlyAttrIdentifier);
  AddAttribute(fIdentifierAttri);

  fKeyAttri           := TSynHighlighterAttributes.Create(SYNS_AttrReservedWord, SYNS_FriendlyAttrReservedWord);
  fKeyAttri.Style     := [fsBold];

  AddAttribute(fKeyAttri);
  fNumberAttri        := TSynHighlighterAttributes.Create(SYNS_AttrNumber, SYNS_FriendlyAttrNumber);
  fNumberAttri.Foreground := clRed;
  AddAttribute(fNumberAttri);
  fSpaceAttri         := TSynHighlighterAttributes.Create(SYNS_AttrSpace, SYNS_FriendlyAttrSpace);
  AddAttribute(fSpaceAttri);
  fStringAttri        := TSynHighlighterAttributes.Create(SYNS_AttrString, SYNS_FriendlyAttrString);
  AddAttribute(fStringAttri);
  fSymbolAttri        := TSynHighlighterAttributes.Create(SYNS_AttrSymbol, SYNS_FriendlyAttrSymbol);
  AddAttribute(fSymbolAttri);

  fDirectivesAttri   := TSynHighlighterAttributes.Create('Directives', 'Directives');
  fDirectivesAttri.Foreground := $008CFF;
  fDirectivesAttri.Style := [fsBold];
  AddAttribute(fDirectivesAttri);

  fRegisterAttri := TSynHighlighterAttributes.Create('Register', 'Register');
  fRegisterAttri.Foreground := $32CD32;
  fRegisterAttri.Style := [fsBold];
  AddAttribute(fRegisterAttri);

  fApiAttri := TSynHighlighterAttributes.Create('Api', 'Api');
  fApiAttri.Foreground := clYellow;
  //fApiAttri.Style := [fsBold];
  AddAttribute(fApiAttri);

  fIncludeAttri := TSynHighlighterAttributes.Create('Include', 'Include');
  fIncludeAttri.Foreground := clMoneyGreen;
  //fApiAttri.Style := [fsBold];
  AddAttribute(fIncludeAttri);

  EnumerateKeywords(Ord(tkKey), Mnemonics, IsIdentChar, DoAddKeyword);
  EnumerateKeywords(Ord(tkDirectives), Directives, IsIdentChar, DoAddDirectivesKeyword);
  EnumerateKeywords(Ord(tkRegister), Registers, IsIdentChar, DoAddRegisterKeyword);
  EnumerateKeywords(Ord(tkApi), Apis, IsIdentChar, DoAddApiKeyword);

  SetAttributesOnChange(DefHighlightChange);
  fDefaultFilter      := SYNS_FilterX86Assembly;
end;

destructor TSynAsmMASMSyn.Destroy;
begin
  fKeywords.Free;
  fDirectivesKeywords.Free;
  fRegisterKeywords.Free;
  fApiKeywords.Free;
  inherited Destroy;
end;

procedure TSynAsmMASMSyn.CommentProc;
begin
  fTokenID := tkComment;
  repeat
    Inc(Run);
  until IsLineEnd(Run);
end;

procedure TSynAsmMASMSyn.CRProc;
begin
  fTokenID := tkSpace;
  Inc(Run);
  if fLine[Run] = #10 then Inc(Run);
end;

procedure TSynAsmMASMSyn.GreaterProc;
begin
  Inc(Run);
  fTokenID := tkSymbol;
  if fLine[Run] = '=' then Inc(Run);
end;

procedure TSynAsmMASMSyn.IdentProc;
begin
  fTokenID := IdentKind((fLine + Run));
  inc(Run, fStringLen);
  while IsIdentChar(fLine[Run]) do inc(Run);
end;

procedure TSynAsmMASMSyn.LFProc;
begin
  fTokenID := tkSpace;
  inc(Run);
end;

procedure TSynAsmMASMSyn.LowerProc;
begin
  Inc(Run);
  fTokenID := tkSymbol;
  if CharInSet(fLine[Run], ['=', '>']) then Inc(Run);
end;

procedure TSynAsmMASMSyn.NullProc;
begin
  fTokenID := tkNull;
  inc(Run);
end;

procedure TSynAsmMASMSyn.NumberProc;

  function IsNumberChar: Boolean;
  begin
    case fLine[Run] of
      //'0'..'9', '.', 'a'..'f', 'h', 'A'..'F', 'H':
      '0'..'9', 'a'..'f', 'h', 'A'..'F', 'H': Result := True;   // THJ
      else
        Result := False;
    end;
  end;

begin
  inc(Run);
  fTokenID := tkNumber;
  while IsNumberChar do
    Inc(Run);
end;

procedure TSynAsmMASMSyn.SlashProc;
begin
  Inc(Run);
  if fLine[Run] = '/' then begin
    fTokenID := tkComment;
    repeat
      Inc(Run);
    until IsLineEnd(Run);
  end else
    fTokenID := tkSymbol;
end;

procedure TSynAsmMASMSyn.IncludeProc;
begin
  fTokenID := tkInclude;
  repeat
    Inc(Run);
  until IsLineEnd(Run);
end;

procedure TSynAsmMASMSyn.SpaceProc;
begin
  fTokenID := tkSpace;
  repeat
    Inc(Run);
  until (fLine[Run] > #32) or IsLineEnd(Run);
end;

procedure TSynAsmMASMSyn.StringProc;
begin
  fTokenID := tkString;
  if (FLine[Run + 1] = #34) and (FLine[Run + 2] = #34) then
    inc(Run, 2);
  repeat
    case FLine[Run] of
      #0, #10, #13: break;
    end;
    inc(Run);
  until FLine[Run] = #34;
  if FLine[Run] <> #0 then inc(Run);
end;

procedure TSynAsmMASMSyn.SingleQuoteStringProc;
begin
  fTokenID := tkString;
  if (FLine[Run + 1] = #39) and (FLine[Run + 2] = #39) then
    inc(Run, 2);
  repeat
    case FLine[Run] of
      #0, #10, #13: break;
    end;
    inc(Run);
  until FLine[Run] = #39;
  if FLine[Run] <> #0 then inc(Run);
end;

procedure TSynAsmMASMSyn.SymbolProc;
begin
  inc(Run);
  fTokenID := tkSymbol;
end;

procedure TSynAsmMASMSyn.UnknownProc;
begin
  inc(Run);
  fTokenID := tkIdentifier;
end;

procedure TSynAsmMASMSyn.Next;
begin
  fTokenPos := Run;
  case fLine[Run] of
     #0: NullProc;
    #10: LFProc;
    #13: CRProc;
    #34: StringProc;
    #39: SingleQuoteStringProc;
    '>': GreaterProc;
    '<': LowerProc;
    '/': SlashProc;
    '\': IncludeProc;
    //'A'..'Z', 'a'..'z', '_': IdentProc;
    'A'..'Z', 'a'..'z', '_', '.', '?', '[', ']': IdentProc;   // THJ
    '0'..'9': NumberProc;
    #1..#9, #11, #12, #14..#32: SpaceProc;
    '#', ';': CommentProc;
    //'.', ':', '&', '{', '}', '=', '^', '-', '+', '(', ')', '*': SymbolProc;
    ':', '&', '{', '}', '^', '-', '+', '(', ')', '*': SymbolProc;
    else
      UnknownProc;
  end;
  inherited;
end;

function TSynAsmMASMSyn.GetDefaultAttribute(Index: integer): TSynHighlighterAttributes;
begin
  case Index of
    SYN_ATTR_COMMENT: Result := fCommentAttri;
    SYN_ATTR_IDENTIFIER: Result := fIdentifierAttri;
    SYN_ATTR_KEYWORD: Result := fKeyAttri;
    SYN_ATTR_STRING: Result := fStringAttri;
    SYN_ATTR_WHITESPACE: Result := fSpaceAttri;
    SYN_ATTR_SYMBOL: Result := fSymbolAttri;
  else
    Result := nil;
  end;
end;

function TSynAsmMASMSyn.GetEol: Boolean;
begin
  Result := Run = fLineLen + 1;
end;

function TSynAsmMASMSyn.GetTokenAttribute: TSynHighlighterAttributes;
begin
  case fTokenID of
    tkComment: Result := fCommentAttri;
    tkIdentifier: Result := fIdentifierAttri;
    tkKey: Result := fKeyAttri;
    tkNumber: Result := fNumberAttri;
    tkSpace: Result := fSpaceAttri;
    tkString: Result := fStringAttri;
    tkSymbol: Result := fSymbolAttri;
    tkUnknown: Result := fIdentifierAttri;
    tkDirectives: Result := fDirectivesAttri;
    tkRegister: Result := fRegisterAttri;
    tkApi: Result := fApiAttri;
    tkInclude: Result := fIncludeAttri;
    else Result := nil;
  end;
end;

function TSynAsmMASMSyn.GetTokenKind: integer;
begin
  Result := Ord(fTokenId);
end;

function TSynAsmMASMSyn.GetTokenID: TtkTokenKind;
begin
  Result := fTokenId;
end;

class function TSynAsmMASMSyn.GetLanguageName: string;
begin
  Result := SYNS_LangMASM;
end;

function TSynAsmMASMSyn.IsFilterStored: Boolean;
begin
  Result := fDefaultFilter <> SYNS_FilterX86Assembly;
end;

function TSynAsmMASMSyn.GetSampleSource: UnicodeString;
begin
  Result := '; x86 assembly sample source'#13#10 +
            '  CODE	SEGMENT	BYTE PUBLIC'#13#10 +
            '    ASSUME	CS:CODE'#13#10 +
            #13#10 +
            '    PUSH SS'#13#10 +
            '    POP DS'#13#10 +
            '    MOV AX, AABBh'#13#10 +
            '    MOV	BYTE PTR ES:[DI], 255'#13#10 +
            '    JMP SHORT AsmEnd'#13#10 +
            #13#10 +
            '  welcomeMsg DB ''Hello World'', 0'#13#10 +
            #13#10 +
            '  AsmEnd:'#13#10 +
            '    MOV AX, 0'#13#10 +
            #13#10 +
            '  CODE	ENDS'#13#10 +
            'END';
end;

class function TSynAsmMASMSyn.GetFriendlyLanguageName: UnicodeString;
begin
  Result := SYNS_FriendlyLangMASM;
end;

initialization
{$IFNDEF SYN_CPPB_1}
  RegisterPlaceableHighlighter(TSynAsmMASMSyn);
{$ENDIF}
end.

