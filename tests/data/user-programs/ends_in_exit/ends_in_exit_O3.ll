; ModuleID = '/workspace/user-programs/ends_in_exit.c'
source_filename = "/workspace/user-programs/ends_in_exit.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@.str = private unnamed_addr constant [12 x i8] c"not a digit\00", align 1, !dbg !0
@stderr = external local_unnamed_addr global ptr, align 8
@.str.2 = private unnamed_addr constant [11 x i8] c"error: %s\0A\00", align 1, !dbg !7

; Function Attrs: nofree nounwind uwtable
define dso_local range(i32 0, 10) i32 @parse_digit(i8 noundef signext %c) local_unnamed_addr #0 !dbg !32 {
entry:
    #dbg_value(i8 %c, !37, !DIExpression(), !38)
  %0 = add i8 %c, -58, !dbg !39
  %or.cond = icmp ult i8 %0, -10, !dbg !39
  br i1 %or.cond, label %if.then, label %if.end, !dbg !39

if.then:                                          ; preds = %entry
  tail call fastcc void @fail(), !dbg !41
  unreachable, !dbg !43

if.end:                                           ; preds = %entry
  %conv = zext nneg i8 %c to i32, !dbg !44
  %sub = add nsw i32 %conv, -48, !dbg !45
  ret i32 %sub, !dbg !46
}

; Function Attrs: cold nofree noreturn nounwind uwtable
define internal fastcc void @fail() unnamed_addr #1 !dbg !47 {
entry:
    #dbg_value(ptr @.str, !53, !DIExpression(), !54)
  %0 = load ptr, ptr @stderr, align 8, !dbg !55, !tbaa !56
  %call = tail call i32 (ptr, ptr, ...) @fprintf(ptr noundef %0, ptr noundef nonnull @.str.2, ptr noundef nonnull @.str) #5, !dbg !59
  tail call void @exit(i32 noundef 1) #6, !dbg !60
  unreachable, !dbg !60
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local noundef range(i32 0, 2) i32 @main() local_unnamed_addr #2 !dbg !61 {
parse_digit.exit.3:
    #dbg_value(i32 poison, !65, !DIExpression(), !68)
  ret i32 0, !dbg !69
}

; Function Attrs: nofree nounwind
declare !dbg !70 noundef i32 @fprintf(ptr noundef captures(none), ptr noundef readonly captures(none), ...) local_unnamed_addr #3

; Function Attrs: nofree noreturn nounwind
declare void @exit(i32 noundef) local_unnamed_addr #4

attributes #0 = { nofree nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { cold nofree noreturn nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { nofree nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #4 = { nofree noreturn nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #5 = { cold nounwind }
attributes #6 = { cold noreturn nounwind }

!llvm.dbg.cu = !{!12}
!llvm.module.flags = !{!20, !21, !22, !23, !24, !25, !26}
!llvm.ident = !{!27}
!llvm.errno.tbaa = !{!28}

!0 = !DIGlobalVariableExpression(var: !1, expr: !DIExpression())
!1 = distinct !DIGlobalVariable(scope: null, file: !2, line: 11, type: !3, isLocal: true, isDefinition: true)
!2 = !DIFile(filename: "user-programs/ends_in_exit.c", directory: "/workspace", checksumkind: CSK_MD5, checksum: "e5230e764d01bf37a1ff141909c00bde")
!3 = !DICompositeType(tag: DW_TAG_array_type, baseType: !4, size: 96, elements: !5)
!4 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!5 = !{!6}
!6 = !DISubrange(count: 12)
!7 = !DIGlobalVariableExpression(var: !8, expr: !DIExpression())
!8 = distinct !DIGlobalVariable(scope: null, file: !2, line: 5, type: !9, isLocal: true, isDefinition: true)
!9 = !DICompositeType(tag: DW_TAG_array_type, baseType: !4, size: 88, elements: !10)
!10 = !{!11}
!11 = !DISubrange(count: 11)
!12 = distinct !DICompileUnit(language: DW_LANG_C11, file: !13, producer: "clang version 22.1.8 (https://github.com/llvm/llvm-project ca7933e47d3a3451d81e72ac174dcb5aa28b59d1)", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, globals: !14, splitDebugInlining: false, nameTableKind: None)
!13 = !DIFile(filename: "/workspace/user-programs/ends_in_exit.c", directory: "/workspace", checksumkind: CSK_MD5, checksum: "e5230e764d01bf37a1ff141909c00bde")
!14 = !{!0, !15, !7}
!15 = !DIGlobalVariableExpression(var: !16, expr: !DIExpression())
!16 = distinct !DIGlobalVariable(scope: null, file: !2, line: 18, type: !17, isLocal: true, isDefinition: true)
!17 = !DICompositeType(tag: DW_TAG_array_type, baseType: !4, size: 40, elements: !18)
!18 = !{!19}
!19 = !DISubrange(count: 5)
!20 = !{i32 7, !"Dwarf Version", i32 5}
!21 = !{i32 2, !"Debug Info Version", i32 3}
!22 = !{i32 1, !"wchar_size", i32 4}
!23 = !{i32 8, !"PIC Level", i32 2}
!24 = !{i32 7, !"PIE Level", i32 2}
!25 = !{i32 7, !"uwtable", i32 2}
!26 = !{i32 7, !"debug-info-assignment-tracking", i1 true}
!27 = !{!"clang version 22.1.8 (https://github.com/llvm/llvm-project ca7933e47d3a3451d81e72ac174dcb5aa28b59d1)"}
!28 = !{!29, !29, i64 0}
!29 = !{!"int", !30, i64 0}
!30 = !{!"omnipotent char", !31, i64 0}
!31 = !{!"Simple C/C++ TBAA"}
!32 = distinct !DISubprogram(name: "parse_digit", scope: !2, file: !2, line: 9, type: !33, scopeLine: 9, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !12, retainedNodes: !36, keyInstructions: true)
!33 = !DISubroutineType(types: !34)
!34 = !{!35, !4}
!35 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!36 = !{!37}
!37 = !DILocalVariable(name: "c", arg: 1, scope: !32, file: !2, line: 9, type: !4)
!38 = !DILocation(line: 0, scope: !32)
!39 = !DILocation(line: 10, column: 17, scope: !40, atomGroup: 1, atomRank: 1)
!40 = distinct !DILexicalBlock(scope: !32, file: !2, line: 10, column: 9)
!41 = !DILocation(line: 11, column: 9, scope: !42)
!42 = distinct !DILexicalBlock(scope: !40, file: !2, line: 10, column: 29)
!43 = !DILocation(line: 12, column: 5, scope: !42)
!44 = !DILocation(line: 10, column: 9, scope: !40)
!45 = !DILocation(line: 13, column: 14, scope: !32, atomGroup: 3, atomRank: 2)
!46 = !DILocation(line: 13, column: 5, scope: !32, atomGroup: 3, atomRank: 1)
!47 = distinct !DISubprogram(name: "fail", scope: !2, file: !2, line: 4, type: !48, scopeLine: 4, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition | DISPFlagOptimized, unit: !12, retainedNodes: !52, keyInstructions: true)
!48 = !DISubroutineType(types: !49)
!49 = !{null, !50}
!50 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !51, size: 64)
!51 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !4)
!52 = !{!53}
!53 = !DILocalVariable(name: "message", arg: 1, scope: !47, file: !2, line: 4, type: !50)
!54 = !DILocation(line: 0, scope: !47)
!55 = !DILocation(line: 5, column: 13, scope: !47)
!56 = !{!57, !57, i64 0}
!57 = !{!"p1 _ZTS8_IO_FILE", !58, i64 0}
!58 = !{!"any pointer", !30, i64 0}
!59 = !DILocation(line: 5, column: 5, scope: !47)
!60 = !DILocation(line: 6, column: 5, scope: !47)
!61 = distinct !DISubprogram(name: "main", scope: !2, file: !2, line: 16, type: !62, scopeLine: 16, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !12, retainedNodes: !64, keyInstructions: true)
!62 = !DISubroutineType(types: !63)
!63 = !{!35}
!64 = !{!65, !66}
!65 = !DILocalVariable(name: "total", scope: !61, file: !2, line: 17, type: !35)
!66 = !DILocalVariable(name: "p", scope: !67, file: !2, line: 18, type: !50)
!67 = distinct !DILexicalBlock(scope: !61, file: !2, line: 18, column: 5)
!68 = !DILocation(line: 0, scope: !61)
!69 = !DILocation(line: 21, column: 5, scope: !61, atomGroup: 9, atomRank: 1)
!70 = !DISubprogram(name: "fprintf", scope: !71, file: !71, line: 357, type: !72, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!71 = !DIFile(filename: "/usr/include/stdio.h", directory: "", checksumkind: CSK_MD5, checksum: "1e435c46987a169d9f9186f63a512303")
!72 = !DISubroutineType(types: !73)
!73 = !{!35, !74, !136, null}
!74 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !75)
!75 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !76, size: 64)
!76 = !DIDerivedType(tag: DW_TAG_typedef, name: "FILE", file: !77, line: 7, baseType: !78)
!77 = !DIFile(filename: "/usr/include/x86_64-linux-gnu/bits/types/FILE.h", directory: "", checksumkind: CSK_MD5, checksum: "571f9fb6223c42439075fdde11a0de5d")
!78 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "_IO_FILE", file: !79, line: 49, size: 1728, elements: !80)
!79 = !DIFile(filename: "/usr/include/x86_64-linux-gnu/bits/types/struct_FILE.h", directory: "", checksumkind: CSK_MD5, checksum: "7a6d4a00a37ee6b9a40cd04bd01f5d00")
!80 = !{!81, !82, !84, !85, !86, !87, !88, !89, !90, !91, !92, !93, !94, !97, !99, !100, !101, !105, !107, !109, !113, !116, !118, !121, !124, !125, !127, !131, !132}
!81 = !DIDerivedType(tag: DW_TAG_member, name: "_flags", scope: !78, file: !79, line: 51, baseType: !35, size: 32)
!82 = !DIDerivedType(tag: DW_TAG_member, name: "_IO_read_ptr", scope: !78, file: !79, line: 54, baseType: !83, size: 64, offset: 64)
!83 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !4, size: 64)
!84 = !DIDerivedType(tag: DW_TAG_member, name: "_IO_read_end", scope: !78, file: !79, line: 55, baseType: !83, size: 64, offset: 128)
!85 = !DIDerivedType(tag: DW_TAG_member, name: "_IO_read_base", scope: !78, file: !79, line: 56, baseType: !83, size: 64, offset: 192)
!86 = !DIDerivedType(tag: DW_TAG_member, name: "_IO_write_base", scope: !78, file: !79, line: 57, baseType: !83, size: 64, offset: 256)
!87 = !DIDerivedType(tag: DW_TAG_member, name: "_IO_write_ptr", scope: !78, file: !79, line: 58, baseType: !83, size: 64, offset: 320)
!88 = !DIDerivedType(tag: DW_TAG_member, name: "_IO_write_end", scope: !78, file: !79, line: 59, baseType: !83, size: 64, offset: 384)
!89 = !DIDerivedType(tag: DW_TAG_member, name: "_IO_buf_base", scope: !78, file: !79, line: 60, baseType: !83, size: 64, offset: 448)
!90 = !DIDerivedType(tag: DW_TAG_member, name: "_IO_buf_end", scope: !78, file: !79, line: 61, baseType: !83, size: 64, offset: 512)
!91 = !DIDerivedType(tag: DW_TAG_member, name: "_IO_save_base", scope: !78, file: !79, line: 64, baseType: !83, size: 64, offset: 576)
!92 = !DIDerivedType(tag: DW_TAG_member, name: "_IO_backup_base", scope: !78, file: !79, line: 65, baseType: !83, size: 64, offset: 640)
!93 = !DIDerivedType(tag: DW_TAG_member, name: "_IO_save_end", scope: !78, file: !79, line: 66, baseType: !83, size: 64, offset: 704)
!94 = !DIDerivedType(tag: DW_TAG_member, name: "_markers", scope: !78, file: !79, line: 68, baseType: !95, size: 64, offset: 768)
!95 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !96, size: 64)
!96 = !DICompositeType(tag: DW_TAG_structure_type, name: "_IO_marker", file: !79, line: 36, flags: DIFlagFwdDecl)
!97 = !DIDerivedType(tag: DW_TAG_member, name: "_chain", scope: !78, file: !79, line: 70, baseType: !98, size: 64, offset: 832)
!98 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !78, size: 64)
!99 = !DIDerivedType(tag: DW_TAG_member, name: "_fileno", scope: !78, file: !79, line: 72, baseType: !35, size: 32, offset: 896)
!100 = !DIDerivedType(tag: DW_TAG_member, name: "_flags2", scope: !78, file: !79, line: 73, baseType: !35, size: 32, offset: 928)
!101 = !DIDerivedType(tag: DW_TAG_member, name: "_old_offset", scope: !78, file: !79, line: 74, baseType: !102, size: 64, offset: 960)
!102 = !DIDerivedType(tag: DW_TAG_typedef, name: "__off_t", file: !103, line: 152, baseType: !104)
!103 = !DIFile(filename: "/usr/include/x86_64-linux-gnu/bits/types.h", directory: "", checksumkind: CSK_MD5, checksum: "e1865d9fe29fe1b5ced550b7ba458f9e")
!104 = !DIBasicType(name: "long", size: 64, encoding: DW_ATE_signed)
!105 = !DIDerivedType(tag: DW_TAG_member, name: "_cur_column", scope: !78, file: !79, line: 77, baseType: !106, size: 16, offset: 1024)
!106 = !DIBasicType(name: "unsigned short", size: 16, encoding: DW_ATE_unsigned)
!107 = !DIDerivedType(tag: DW_TAG_member, name: "_vtable_offset", scope: !78, file: !79, line: 78, baseType: !108, size: 8, offset: 1040)
!108 = !DIBasicType(name: "signed char", size: 8, encoding: DW_ATE_signed_char)
!109 = !DIDerivedType(tag: DW_TAG_member, name: "_shortbuf", scope: !78, file: !79, line: 79, baseType: !110, size: 8, offset: 1048)
!110 = !DICompositeType(tag: DW_TAG_array_type, baseType: !4, size: 8, elements: !111)
!111 = !{!112}
!112 = !DISubrange(count: 1)
!113 = !DIDerivedType(tag: DW_TAG_member, name: "_lock", scope: !78, file: !79, line: 81, baseType: !114, size: 64, offset: 1088)
!114 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !115, size: 64)
!115 = !DIDerivedType(tag: DW_TAG_typedef, name: "_IO_lock_t", file: !79, line: 43, baseType: null)
!116 = !DIDerivedType(tag: DW_TAG_member, name: "_offset", scope: !78, file: !79, line: 89, baseType: !117, size: 64, offset: 1152)
!117 = !DIDerivedType(tag: DW_TAG_typedef, name: "__off64_t", file: !103, line: 153, baseType: !104)
!118 = !DIDerivedType(tag: DW_TAG_member, name: "_codecvt", scope: !78, file: !79, line: 91, baseType: !119, size: 64, offset: 1216)
!119 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !120, size: 64)
!120 = !DICompositeType(tag: DW_TAG_structure_type, name: "_IO_codecvt", file: !79, line: 37, flags: DIFlagFwdDecl)
!121 = !DIDerivedType(tag: DW_TAG_member, name: "_wide_data", scope: !78, file: !79, line: 92, baseType: !122, size: 64, offset: 1280)
!122 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !123, size: 64)
!123 = !DICompositeType(tag: DW_TAG_structure_type, name: "_IO_wide_data", file: !79, line: 38, flags: DIFlagFwdDecl)
!124 = !DIDerivedType(tag: DW_TAG_member, name: "_freeres_list", scope: !78, file: !79, line: 93, baseType: !98, size: 64, offset: 1344)
!125 = !DIDerivedType(tag: DW_TAG_member, name: "_freeres_buf", scope: !78, file: !79, line: 94, baseType: !126, size: 64, offset: 1408)
!126 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
!127 = !DIDerivedType(tag: DW_TAG_member, name: "__pad5", scope: !78, file: !79, line: 95, baseType: !128, size: 64, offset: 1472)
!128 = !DIDerivedType(tag: DW_TAG_typedef, name: "size_t", file: !129, line: 18, baseType: !130)
!129 = !DIFile(filename: "/opt/llvm/lib/clang/22/include/__stddef_size_t.h", directory: "", checksumkind: CSK_MD5, checksum: "2c44e821a2b1951cde2eb0fb2e656867")
!130 = !DIBasicType(name: "unsigned long", size: 64, encoding: DW_ATE_unsigned)
!131 = !DIDerivedType(tag: DW_TAG_member, name: "_mode", scope: !78, file: !79, line: 96, baseType: !35, size: 32, offset: 1536)
!132 = !DIDerivedType(tag: DW_TAG_member, name: "_unused2", scope: !78, file: !79, line: 98, baseType: !133, size: 160, offset: 1568)
!133 = !DICompositeType(tag: DW_TAG_array_type, baseType: !4, size: 160, elements: !134)
!134 = !{!135}
!135 = !DISubrange(count: 20)
!136 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !50)
