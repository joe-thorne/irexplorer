; ModuleID = '/workspace/user-programs/computed_goto.c'
source_filename = "/workspace/user-programs/computed_goto.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@run.ops = internal unnamed_addr constant [3 x ptr] [ptr blockaddress(@run, %increment), ptr blockaddress(@run, %double_it), ptr blockaddress(@run, %return)], align 16, !dbg !0
@__const.main.program = private unnamed_addr constant [5 x i8] c"\00\01\00\01\02", align 1

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read) uwtable
define dso_local i32 @run(ptr noundef readonly captures(none) %code, i32 noundef %n) local_unnamed_addr #0 !dbg !2 {
entry:
    #dbg_value(ptr %code, !14, !DIExpression(), !38)
    #dbg_value(i32 %n, !15, !DIExpression(), !38)
    #dbg_value(i32 0, !16, !DIExpression(), !38)
    #dbg_value(i32 0, !17, !DIExpression(), !38)
  br label %indirectgoto, !dbg !39

increment:                                        ; preds = %indirectgoto
    #dbg_label(!18, !40)
  %add = add nsw i32 %value.0, 1, !dbg !41
    #dbg_value(i32 %add, !16, !DIExpression(), !38)
  %inc = add nsw i32 %pc.0, 1, !dbg !42
    #dbg_value(i32 %inc, !17, !DIExpression(), !38)
  %cmp.not = icmp slt i32 %inc, %n, !dbg !44
  br i1 %cmp.not, label %indirectgoto.backedge, label %return, !dbg !45

indirectgoto.backedge:                            ; preds = %double_it, %increment
  %value.0.be = phi i32 [ %add, %increment ], [ %mul, %double_it ]
  %pc.0.be = phi i32 [ %inc, %increment ], [ %inc7, %double_it ]
  %idxprom3.pn = sext i32 %pc.0.be to i64, !dbg !38
  %idxprom5.pn.in.in = getelementptr inbounds i8, ptr %code, i64 %idxprom3.pn, !dbg !38
  br label %indirectgoto, !dbg !38

double_it:                                        ; preds = %indirectgoto
    #dbg_label(!19, !46)
  %mul = shl nsw i32 %value.0, 1, !dbg !47
    #dbg_value(i32 %mul, !16, !DIExpression(), !38)
  %inc7 = add nsw i32 %pc.0, 1, !dbg !48
    #dbg_value(i32 %inc7, !17, !DIExpression(), !38)
  %cmp8.not = icmp slt i32 %inc7, %n, !dbg !50
  br i1 %cmp8.not, label %indirectgoto.backedge, label %return, !dbg !51

return:                                           ; preds = %indirectgoto, %double_it, %increment
  %retval.0 = phi i32 [ %mul, %double_it ], [ %add, %increment ], [ %value.0, %indirectgoto ], !dbg !38
  ret i32 %retval.0, !dbg !52

indirectgoto:                                     ; preds = %indirectgoto.backedge, %entry
  %value.0 = phi i32 [ 0, %entry ], [ %value.0.be, %indirectgoto.backedge ], !dbg !38
  %pc.0 = phi i32 [ 0, %entry ], [ %pc.0.be, %indirectgoto.backedge ], !dbg !38
  %idxprom1.pn.in.in = phi ptr [ %code, %entry ], [ %idxprom5.pn.in.in, %indirectgoto.backedge ]
  %idxprom1.pn.in = load i8, ptr %idxprom1.pn.in.in, align 1, !dbg !38, !tbaa !53
  %idxprom1.pn = zext i8 %idxprom1.pn.in to i64, !dbg !38
  %indirect.goto.dest.in = getelementptr inbounds nuw ptr, ptr @run.ops, i64 %idxprom1.pn, !dbg !38
  %indirect.goto.dest = load ptr, ptr %indirect.goto.dest.in, align 8, !dbg !38, !tbaa !54
    #dbg_value(i32 %pc.0, !17, !DIExpression(), !38)
    #dbg_value(i32 %value.0, !16, !DIExpression(), !38)
  indirectbr ptr %indirect.goto.dest, [label %increment, label %double_it, label %return]
}

; Function Attrs: nofree norecurse nosync nounwind memory(none) uwtable
define dso_local range(i32 0, 2) i32 @main() local_unnamed_addr #1 !dbg !56 {
entry:
    #dbg_assign(i1 poison, !60, !DIExpression(), !64, ptr @__const.main.program, !DIExpression(), !65)
    #dbg_assign(i1 poison, !60, !DIExpression(), !66, ptr @__const.main.program, !DIExpression(), !65)
  %call = tail call i32 @run(ptr noundef nonnull @__const.main.program, i32 noundef 5), !dbg !67
  %cmp = icmp ne i32 %call, 6, !dbg !68
  %cond = zext i1 %cmp to i32, !dbg !69
  ret i32 %cond, !dbg !70
}

attributes #0 = { nofree norecurse nosync nounwind memory(argmem: read) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nofree norecurse nosync nounwind memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }

!llvm.dbg.cu = !{!10}
!llvm.module.flags = !{!26, !27, !28, !29, !30, !31, !32}
!llvm.ident = !{!33}
!llvm.errno.tbaa = !{!34}

!0 = !DIGlobalVariableExpression(var: !1, expr: !DIExpression())
!1 = distinct !DIGlobalVariable(name: "ops", scope: !2, file: !3, line: 2, type: !21, isLocal: true, isDefinition: true)
!2 = distinct !DISubprogram(name: "run", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !10, retainedNodes: !13, keyInstructions: true)
!3 = !DIFile(filename: "user-programs/computed_goto.c", directory: "/workspace", checksumkind: CSK_MD5, checksum: "e6deaafbfcb1514f91bb07878ad5625d")
!4 = !DISubroutineType(types: !5)
!5 = !{!6, !7, !6}
!6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !8, size: 64)
!8 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !9)
!9 = !DIBasicType(name: "unsigned char", size: 8, encoding: DW_ATE_unsigned_char)
!10 = distinct !DICompileUnit(language: DW_LANG_C11, file: !11, producer: "clang version 22.1.8 (https://github.com/llvm/llvm-project ca7933e47d3a3451d81e72ac174dcb5aa28b59d1)", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, globals: !12, splitDebugInlining: false, nameTableKind: None)
!11 = !DIFile(filename: "/workspace/user-programs/computed_goto.c", directory: "/workspace", checksumkind: CSK_MD5, checksum: "e6deaafbfcb1514f91bb07878ad5625d")
!12 = !{!0}
!13 = !{!14, !15, !16, !17, !18, !19, !20}
!14 = !DILocalVariable(name: "code", arg: 1, scope: !2, file: !3, line: 1, type: !7)
!15 = !DILocalVariable(name: "n", arg: 2, scope: !2, file: !3, line: 1, type: !6)
!16 = !DILocalVariable(name: "value", scope: !2, file: !3, line: 3, type: !6)
!17 = !DILocalVariable(name: "pc", scope: !2, file: !3, line: 4, type: !6)
!18 = !DILabel(scope: !2, name: "increment", file: !3, line: 6, column: 1)
!19 = !DILabel(scope: !2, name: "double_it", file: !3, line: 10, column: 1)
!20 = !DILabel(scope: !2, name: "stop", file: !3, line: 14, column: 1)
!21 = !DICompositeType(tag: DW_TAG_array_type, baseType: !22, size: 192, elements: !24)
!22 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !23)
!23 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
!24 = !{!25}
!25 = !DISubrange(count: 3)
!26 = !{i32 7, !"Dwarf Version", i32 5}
!27 = !{i32 2, !"Debug Info Version", i32 3}
!28 = !{i32 1, !"wchar_size", i32 4}
!29 = !{i32 8, !"PIC Level", i32 2}
!30 = !{i32 7, !"PIE Level", i32 2}
!31 = !{i32 7, !"uwtable", i32 2}
!32 = !{i32 7, !"debug-info-assignment-tracking", i1 true}
!33 = !{!"clang version 22.1.8 (https://github.com/llvm/llvm-project ca7933e47d3a3451d81e72ac174dcb5aa28b59d1)"}
!34 = !{!35, !35, i64 0}
!35 = !{!"int", !36, i64 0}
!36 = !{!"omnipotent char", !37, i64 0}
!37 = !{!"Simple C/C++ TBAA"}
!38 = !DILocation(line: 0, scope: !2)
!39 = !DILocation(line: 5, column: 5, scope: !2, atomGroup: 3, atomRank: 1)
!40 = !DILocation(line: 6, column: 1, scope: !2)
!41 = !DILocation(line: 7, column: 11, scope: !2, atomGroup: 4, atomRank: 2)
!42 = !DILocation(line: 8, column: 9, scope: !43, atomGroup: 5, atomRank: 2)
!43 = distinct !DILexicalBlock(scope: !2, file: !3, line: 8, column: 9)
!44 = !DILocation(line: 8, column: 14, scope: !43, atomGroup: 6, atomRank: 2)
!45 = !DILocation(line: 8, column: 14, scope: !43, atomGroup: 6, atomRank: 1)
!46 = !DILocation(line: 10, column: 1, scope: !2)
!47 = !DILocation(line: 11, column: 11, scope: !2, atomGroup: 9, atomRank: 2)
!48 = !DILocation(line: 12, column: 9, scope: !49, atomGroup: 10, atomRank: 2)
!49 = distinct !DILexicalBlock(scope: !2, file: !3, line: 12, column: 9)
!50 = !DILocation(line: 12, column: 14, scope: !49, atomGroup: 11, atomRank: 2)
!51 = !DILocation(line: 12, column: 14, scope: !49, atomGroup: 11, atomRank: 1)
!52 = !DILocation(line: 16, column: 1, scope: !2, atomGroup: 15, atomRank: 1)
!53 = !{!36, !36, i64 0}
!54 = !{!55, !55, i64 0}
!55 = !{!"any pointer", !36, i64 0}
!56 = distinct !DISubprogram(name: "main", scope: !3, file: !3, line: 18, type: !57, scopeLine: 18, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !10, retainedNodes: !59, keyInstructions: true)
!57 = !DISubroutineType(types: !58)
!58 = !{!6}
!59 = !{!60}
!60 = !DILocalVariable(name: "program", scope: !56, file: !3, line: 19, type: !61)
!61 = !DICompositeType(tag: DW_TAG_array_type, baseType: !8, size: 40, elements: !62)
!62 = !{!63}
!63 = !DISubrange(count: 5)
!64 = distinct !DIAssignID()
!65 = !DILocation(line: 0, scope: !56)
!66 = distinct !DIAssignID()
!67 = !DILocation(line: 20, column: 12, scope: !56)
!68 = !DILocation(line: 20, column: 28, scope: !56)
!69 = !DILocation(line: 20, column: 12, scope: !56, atomGroup: 3, atomRank: 2)
!70 = !DILocation(line: 20, column: 5, scope: !56, atomGroup: 3, atomRank: 1)
