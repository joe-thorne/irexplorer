; ModuleID = '/workspace/out/computed_goto_09_indvars.ll'
source_filename = "/workspace/user-programs/computed_goto.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@run.ops = internal constant [3 x ptr] [ptr blockaddress(@run, %increment), ptr blockaddress(@run, %double_it), ptr blockaddress(@run, %return)], align 16, !dbg !0
@__const.main.program = private unnamed_addr constant [5 x i8] c"\00\01\00\01\02", align 1

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @run(ptr noundef %code, i32 noundef %n) #0 !dbg !2 {
entry:
    #dbg_value(ptr %code, !27, !DIExpression(), !28)
    #dbg_value(i32 %n, !29, !DIExpression(), !28)
    #dbg_value(i32 0, !30, !DIExpression(), !28)
    #dbg_value(i32 0, !31, !DIExpression(), !28)
  br label %indirectgoto, !dbg !32

increment:                                        ; preds = %indirectgoto
    #dbg_label(!33, !34)
  %add = add nsw i32 %value.0, 1, !dbg !35
    #dbg_value(i32 %add, !30, !DIExpression(), !28)
  %inc = add nsw i32 %pc.0, 1, !dbg !36
    #dbg_value(i32 %inc, !31, !DIExpression(), !28)
  %cmp.not = icmp slt i32 %inc, %n, !dbg !38
  br i1 %cmp.not, label %indirectgoto.backedge, label %return, !dbg !38

indirectgoto.backedge:                            ; preds = %double_it, %increment
  %value.0.be = phi i32 [ %add, %increment ], [ %mul, %double_it ]
  %pc.0.be = phi i32 [ %inc, %increment ], [ %inc7, %double_it ]
  %idxprom3.pn = sext i32 %pc.0.be to i64, !dbg !28
  %idxprom5.pn.in.in = getelementptr inbounds i8, ptr %code, i64 %idxprom3.pn, !dbg !28
  br label %indirectgoto, !dbg !28

double_it:                                        ; preds = %indirectgoto
    #dbg_label(!39, !40)
  %mul = shl nsw i32 %value.0, 1, !dbg !41
    #dbg_value(i32 %mul, !30, !DIExpression(), !28)
  %inc7 = add nsw i32 %pc.0, 1, !dbg !42
    #dbg_value(i32 %inc7, !31, !DIExpression(), !28)
  %cmp8.not = icmp slt i32 %inc7, %n, !dbg !44
  br i1 %cmp8.not, label %indirectgoto.backedge, label %return, !dbg !44

return:                                           ; preds = %indirectgoto, %double_it, %increment
  %retval.0 = phi i32 [ %mul, %double_it ], [ %add, %increment ], [ %value.0, %indirectgoto ], !dbg !28
  ret i32 %retval.0, !dbg !45

indirectgoto:                                     ; preds = %indirectgoto.backedge, %entry
  %value.0 = phi i32 [ 0, %entry ], [ %value.0.be, %indirectgoto.backedge ], !dbg !28
  %pc.0 = phi i32 [ 0, %entry ], [ %pc.0.be, %indirectgoto.backedge ], !dbg !28
  %idxprom1.pn.in.in = phi ptr [ %code, %entry ], [ %idxprom5.pn.in.in, %indirectgoto.backedge ]
  %idxprom1.pn.in = load i8, ptr %idxprom1.pn.in.in, align 1, !dbg !28
  %idxprom1.pn = zext i8 %idxprom1.pn.in to i64, !dbg !28
  %indirect.goto.dest.in = getelementptr inbounds nuw ptr, ptr @run.ops, i64 %idxprom1.pn, !dbg !28
  %indirect.goto.dest = load ptr, ptr %indirect.goto.dest.in, align 8, !dbg !28
    #dbg_value(i32 %pc.0, !31, !DIExpression(), !28)
    #dbg_value(i32 %value.0, !30, !DIExpression(), !28)
  indirectbr ptr %indirect.goto.dest, [label %increment, label %double_it, label %return]
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @main() #0 !dbg !46 {
entry:
  %program = alloca [5 x i8], align 1
    #dbg_declare(ptr %program, !49, !DIExpression(), !53)
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 1 dereferenceable(5) %program, ptr noundef nonnull align 1 dereferenceable(5) @__const.main.program, i64 5, i1 false), !dbg !53
  %call = call i32 @run(ptr noundef nonnull %program, i32 noundef 5), !dbg !54
  %cmp = icmp ne i32 %call, 6, !dbg !55
  %cond = zext i1 %cmp to i32, !dbg !54
  ret i32 %cond, !dbg !56
}

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1

attributes #0 = { noinline nounwind uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }

!llvm.dbg.cu = !{!10}
!llvm.module.flags = !{!19, !20, !21, !22, !23, !24, !25}
!llvm.ident = !{!26}

!0 = !DIGlobalVariableExpression(var: !1, expr: !DIExpression())
!1 = distinct !DIGlobalVariable(name: "ops", scope: !2, file: !3, line: 2, type: !14, isLocal: true, isDefinition: true)
!2 = distinct !DISubprogram(name: "run", scope: !3, file: !3, line: 1, type: !4, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !10, retainedNodes: !13)
!3 = !DIFile(filename: "user-programs/computed_goto.c", directory: "/workspace", checksumkind: CSK_MD5, checksum: "e6deaafbfcb1514f91bb07878ad5625d")
!4 = !DISubroutineType(types: !5)
!5 = !{!6, !7, !6}
!6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !8, size: 64)
!8 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !9)
!9 = !DIBasicType(name: "unsigned char", size: 8, encoding: DW_ATE_unsigned_char)
!10 = distinct !DICompileUnit(language: DW_LANG_C11, file: !11, producer: "clang version 22.1.8 (https://github.com/llvm/llvm-project ca7933e47d3a3451d81e72ac174dcb5aa28b59d1)", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, globals: !12, splitDebugInlining: false, nameTableKind: None)
!11 = !DIFile(filename: "/workspace/user-programs/computed_goto.c", directory: "/workspace", checksumkind: CSK_MD5, checksum: "e6deaafbfcb1514f91bb07878ad5625d")
!12 = !{!0}
!13 = !{}
!14 = !DICompositeType(tag: DW_TAG_array_type, baseType: !15, size: 192, elements: !17)
!15 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !16)
!16 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
!17 = !{!18}
!18 = !DISubrange(count: 3)
!19 = !{i32 7, !"Dwarf Version", i32 5}
!20 = !{i32 2, !"Debug Info Version", i32 3}
!21 = !{i32 1, !"wchar_size", i32 4}
!22 = !{i32 8, !"PIC Level", i32 2}
!23 = !{i32 7, !"PIE Level", i32 2}
!24 = !{i32 7, !"uwtable", i32 2}
!25 = !{i32 7, !"frame-pointer", i32 2}
!26 = !{!"clang version 22.1.8 (https://github.com/llvm/llvm-project ca7933e47d3a3451d81e72ac174dcb5aa28b59d1)"}
!27 = !DILocalVariable(name: "code", arg: 1, scope: !2, file: !3, line: 1, type: !7)
!28 = !DILocation(line: 0, scope: !2)
!29 = !DILocalVariable(name: "n", arg: 2, scope: !2, file: !3, line: 1, type: !6)
!30 = !DILocalVariable(name: "value", scope: !2, file: !3, line: 3, type: !6)
!31 = !DILocalVariable(name: "pc", scope: !2, file: !3, line: 4, type: !6)
!32 = !DILocation(line: 5, column: 5, scope: !2)
!33 = !DILabel(scope: !2, name: "increment", file: !3, line: 6, column: 1)
!34 = !DILocation(line: 6, column: 1, scope: !2)
!35 = !DILocation(line: 7, column: 11, scope: !2)
!36 = !DILocation(line: 8, column: 9, scope: !37)
!37 = distinct !DILexicalBlock(scope: !2, file: !3, line: 8, column: 9)
!38 = !DILocation(line: 8, column: 14, scope: !37)
!39 = !DILabel(scope: !2, name: "double_it", file: !3, line: 10, column: 1)
!40 = !DILocation(line: 10, column: 1, scope: !2)
!41 = !DILocation(line: 11, column: 11, scope: !2)
!42 = !DILocation(line: 12, column: 9, scope: !43)
!43 = distinct !DILexicalBlock(scope: !2, file: !3, line: 12, column: 9)
!44 = !DILocation(line: 12, column: 14, scope: !43)
!45 = !DILocation(line: 16, column: 1, scope: !2)
!46 = distinct !DISubprogram(name: "main", scope: !3, file: !3, line: 18, type: !47, scopeLine: 18, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !10, retainedNodes: !13)
!47 = !DISubroutineType(types: !48)
!48 = !{!6}
!49 = !DILocalVariable(name: "program", scope: !46, file: !3, line: 19, type: !50)
!50 = !DICompositeType(tag: DW_TAG_array_type, baseType: !8, size: 40, elements: !51)
!51 = !{!52}
!52 = !DISubrange(count: 5)
!53 = !DILocation(line: 19, column: 25, scope: !46)
!54 = !DILocation(line: 20, column: 12, scope: !46)
!55 = !DILocation(line: 20, column: 28, scope: !46)
!56 = !DILocation(line: 20, column: 5, scope: !46)
