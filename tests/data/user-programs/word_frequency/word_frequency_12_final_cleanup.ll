; ModuleID = '/workspace/out/word_frequency_11_vectorize.ll'
source_filename = "/workspace/user-programs/word_frequency.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

%struct.table = type { [256 x %struct.entry], i32 }
%struct.entry = type { [24 x i8], i32, i32 }

@main.table = internal global %struct.table zeroinitializer, align 4, !dbg !0
@main.entries = internal global [256 x %struct.entry] zeroinitializer, align 16, !dbg !37
@passage = internal global ptr @.str.4, align 8, !dbg !72
@.str = private unnamed_addr constant [4 x i8] c"fox\00", align 1, !dbg !50
@.str.1 = private unnamed_addr constant [4 x i8] c"cat\00", align 1, !dbg !55
@.str.2 = private unnamed_addr constant [18 x i8] c"fox: %d, cat: %d\0A\00", align 1, !dbg !57
@stderr = external global ptr, align 8
@.str.3 = private unnamed_addr constant [23 x i8] c"table full at word %d\0A\00", align 1, !dbg !62
@.str.4 = private unnamed_addr constant [285 x i8] c"The quick brown fox jumps over the lazy dog. The dog sleeps, and the fox runs into the forest. In the forest the fox finds a river; the river is cold and the fox is quick. A lazy dog never finds the river, but the quick fox always does. Over the hills and over the river the fox runs.\00", align 1, !dbg !67
@.str.5 = private unnamed_addr constant [23 x i8] c"%d words, %d distinct\0A\00", align 1, !dbg !76
@.str.6 = private unnamed_addr constant [11 x i8] c"%-10s %3d \00", align 1, !dbg !78
@.str.7 = private unnamed_addr constant [18 x i8] c"longest word: %s\0A\00", align 1, !dbg !83
@.str.8 = private unnamed_addr constant [27 x i8] c"mean length: %.2f letters\0A\00", align 1, !dbg !85
@.str.9 = private unnamed_addr constant [21 x i8] c"words seen once: %d\0A\00", align 1, !dbg !90

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @main() #0 !dbg !2 {
entry:
  call void @table_init(ptr noundef nonnull @main.table), !dbg !108
  %0 = load ptr, ptr @passage, align 8, !dbg !109
  %call = call i32 @count_words(ptr noundef nonnull @main.table, ptr noundef %0), !dbg !110
    #dbg_value(i32 %call, !111, !DIExpression(), !112)
  %call1 = call i32 @collect(ptr noundef nonnull @main.table, ptr noundef nonnull @main.entries), !dbg !113
    #dbg_value(i32 %call1, !114, !DIExpression(), !112)
  call void @report(ptr noundef nonnull @main.entries, i32 noundef %call1, i32 noundef %call), !dbg !115
  %call2 = call i32 @table_lookup(ptr noundef nonnull @main.table, ptr noundef nonnull @.str), !dbg !116
    #dbg_value(i32 %call2, !117, !DIExpression(), !112)
  %call3 = call i32 @table_lookup(ptr noundef nonnull @main.table, ptr noundef nonnull @.str.1), !dbg !118
    #dbg_value(i32 %call3, !119, !DIExpression(), !112)
  %call4 = call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.2, i32 noundef %call2, i32 noundef %call3) #8, !dbg !120
  %cmp5 = icmp ne i32 %call3, 0, !dbg !121
  %cmp.inv = icmp slt i32 %call2, 1, !dbg !121
  %narrow = or i1 %cmp.inv, %cmp5, !dbg !121
  %not. = zext i1 %narrow to i32, !dbg !121
  ret i32 %not., !dbg !122
}

; Function Attrs: noinline nounwind uwtable
define internal void @table_init(ptr noundef %table) #0 !dbg !123 {
entry:
    #dbg_value(ptr %table, !127, !DIExpression(), !128)
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 4 dereferenceable(8196) %table, i8 0, i64 8196, i1 false), !dbg !129
  ret void, !dbg !130
}

; Function Attrs: noinline nounwind uwtable
define internal i32 @count_words(ptr noundef %table, ptr noundef %text) #0 !dbg !131 {
entry:
  %text.addr = alloca ptr, align 8
  %word = alloca [24 x i8], align 16
    #dbg_value(ptr %table, !134, !DIExpression(), !135)
    #dbg_value(ptr %text, !136, !DIExpression(), !135)
  store ptr %text, ptr %text.addr, align 8
    #dbg_declare(ptr %word, !137, !DIExpression(), !138)
    #dbg_value(i32 0, !139, !DIExpression(), !135)
    #dbg_value(ptr %text.addr, !136, !DIExpression(DW_OP_deref), !135)
  %call1 = call i32 @next_word(ptr noundef nonnull %text.addr, ptr noundef nonnull %word), !dbg !140
  %cmp2 = icmp sgt i32 %call1, 0, !dbg !141
  br i1 %cmp2, label %while.body, label %while.end, !dbg !142

while.body:                                       ; preds = %entry, %if.end
  %position.03 = phi i32 [ %inc, %if.end ], [ 0, %entry ]
    #dbg_value(i32 %position.03, !139, !DIExpression(), !135)
  %call2 = call i32 @table_add(ptr noundef %table, ptr noundef nonnull %word, i32 noundef %position.03), !dbg !143
  %cmp3 = icmp slt i32 %call2, 0, !dbg !146
  br i1 %cmp3, label %if.then, label %if.end, !dbg !146

if.then:                                          ; preds = %while.body
  %0 = load ptr, ptr @stderr, align 8, !dbg !147
  %call4 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %0, ptr noundef nonnull @.str.3, i32 noundef %position.03) #9, !dbg !149
  br label %while.end, !dbg !150

if.end:                                           ; preds = %while.body
  %inc = add nuw nsw i32 %position.03, 1, !dbg !151
    #dbg_value(i32 %inc, !139, !DIExpression(), !135)
    #dbg_value(ptr %text.addr, !136, !DIExpression(DW_OP_deref), !135)
  %call = call i32 @next_word(ptr noundef nonnull %text.addr, ptr noundef nonnull %word), !dbg !140
  %cmp = icmp sgt i32 %call, 0, !dbg !141
  br i1 %cmp, label %while.body, label %while.end, !dbg !142, !llvm.loop !152

while.end:                                        ; preds = %if.end, %if.then, %entry
  %position.02 = phi i32 [ %position.03, %if.then ], [ 0, %entry ], [ %inc, %if.end ]
  ret i32 %position.02, !dbg !155
}

; Function Attrs: noinline nounwind uwtable
define internal i32 @collect(ptr noundef %table, ptr noundef %out) #0 !dbg !156 {
entry:
    #dbg_value(ptr %table, !162, !DIExpression(), !163)
    #dbg_value(ptr %out, !164, !DIExpression(), !163)
    #dbg_value(i32 0, !165, !DIExpression(), !163)
    #dbg_value(i32 0, !166, !DIExpression(), !168)
  br label %for.body, !dbg !169

for.body:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 0, %entry ]
  %n.01 = phi i32 [ %n.1, %for.inc ], [ 0, %entry ]
    #dbg_value(i64 %indvars.iv, !166, !DIExpression(), !168)
    #dbg_value(i32 %n.01, !165, !DIExpression(), !163)
  %arrayidx = getelementptr inbounds nuw %struct.entry, ptr %table, i64 %indvars.iv, !dbg !170
  %count = getelementptr inbounds nuw i8, ptr %arrayidx, i64 24, !dbg !174
  %0 = load i32, ptr %count, align 4, !dbg !174
  %cmp1 = icmp sgt i32 %0, 0, !dbg !175
  br i1 %cmp1, label %if.then, label %for.inc, !dbg !175

if.then:                                          ; preds = %for.body
  %inc = add nsw i32 %n.01, 1, !dbg !176
    #dbg_value(i32 %inc, !165, !DIExpression(), !163)
  %idxprom2 = sext i32 %n.01 to i64, !dbg !178
  %arrayidx3 = getelementptr inbounds %struct.entry, ptr %out, i64 %idxprom2, !dbg !178
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 4 dereferenceable(32) %arrayidx3, ptr noundef nonnull align 4 dereferenceable(32) %arrayidx, i64 32, i1 false), !dbg !179
  br label %for.inc, !dbg !180

for.inc:                                          ; preds = %if.then, %for.body
  %n.1 = phi i32 [ %inc, %if.then ], [ %n.01, %for.body ], !dbg !163
    #dbg_value(i32 %n.1, !165, !DIExpression(), !163)
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1, !dbg !181
    #dbg_value(i64 %indvars.iv.next, !166, !DIExpression(), !168)
  %exitcond.not = icmp eq i64 %indvars.iv.next, 256, !dbg !182
  br i1 %exitcond.not, label %for.end, label %for.body, !dbg !169, !llvm.loop !183

for.end:                                          ; preds = %for.inc
  %conv = sext i32 %n.1 to i64, !dbg !185
  call void @qsort(ptr noundef %out, i64 noundef %conv, i64 noundef 32, ptr noundef nonnull @by_count) #8, !dbg !186
  ret i32 %n.1, !dbg !187
}

; Function Attrs: noinline nounwind uwtable
define internal void @report(ptr noundef %entries, i32 noundef %n, i32 noundef %total) #0 !dbg !188 {
entry:
    #dbg_value(ptr %entries, !193, !DIExpression(), !194)
    #dbg_value(i32 %n, !195, !DIExpression(), !194)
    #dbg_value(i32 %total, !196, !DIExpression(), !194)
    #dbg_value(i32 poison, !197, !DIExpression(), !194)
  %call = call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.5, i32 noundef %total, i32 noundef %n) #8, !dbg !198
    #dbg_value(i32 0, !199, !DIExpression(), !201)
  %cmp11 = icmp sgt i32 %n, 0, !dbg !202
  br i1 %cmp11, label %for.body.lr.ph, label %for.end, !dbg !204

for.body.lr.ph:                                   ; preds = %entry
  %n. = call i32 @llvm.smin.i32(i32 %n, i32 8), !dbg !205
    #dbg_value(i32 %n., !197, !DIExpression(), !194)
  %count9 = getelementptr inbounds nuw i8, ptr %entries, i64 24
  %wide.trip.count = zext nneg i32 %n. to i64, !dbg !202
  br label %for.body, !dbg !204

for.body:                                         ; preds = %for.body, %for.body.lr.ph
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.body ], [ 0, %for.body.lr.ph ]
    #dbg_value(i64 %indvars.iv, !199, !DIExpression(), !201)
  %arrayidx = getelementptr inbounds nuw %struct.entry, ptr %entries, i64 %indvars.iv, !dbg !206
  %count = getelementptr inbounds nuw i8, ptr %arrayidx, i64 24, !dbg !208
  %0 = load i32, ptr %count, align 4, !dbg !208
  %call4 = call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.6, ptr noundef %arrayidx, i32 noundef %0) #8, !dbg !209
  %1 = load i32, ptr %count, align 4, !dbg !210
  %2 = load i32, ptr %count9, align 4, !dbg !211
  call void @print_bar(i32 noundef %1, i32 noundef %2), !dbg !212
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1, !dbg !213
    #dbg_value(i64 %indvars.iv.next, !199, !DIExpression(), !201)
  %exitcond.not = icmp eq i64 %indvars.iv.next, %wide.trip.count, !dbg !202
  br i1 %exitcond.not, label %for.end, label %for.body, !dbg !204, !llvm.loop !214

for.end:                                          ; preds = %for.body, %entry
  %call11 = call ptr @longest(ptr noundef %entries, i32 noundef %n), !dbg !216
    #dbg_value(ptr %call11, !217, !DIExpression(), !194)
  %cmp12.not = icmp eq ptr %call11, null, !dbg !218
  br i1 %cmp12.not, label %if.end, label %if.then, !dbg !218

if.then:                                          ; preds = %for.end
  %call15 = call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.7, ptr noundef nonnull %call11) #8, !dbg !220
  br label %if.end, !dbg !222

if.end:                                           ; preds = %if.then, %for.end
  %call16 = call double @mean_length(ptr noundef %entries, i32 noundef %n), !dbg !223
  %call17 = call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.8, double noundef %call16) #8, !dbg !224
  %call18 = call i32 @singletons(ptr noundef %entries, i32 noundef %n), !dbg !225
  %call19 = call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.9, i32 noundef %call18) #8, !dbg !226
  ret void, !dbg !227
}

; Function Attrs: noinline nounwind uwtable
define internal i32 @table_lookup(ptr noundef %table, ptr noundef %word) #0 !dbg !228 {
entry:
    #dbg_value(ptr %table, !231, !DIExpression(), !232)
    #dbg_value(ptr %word, !233, !DIExpression(), !232)
  %call = call i32 @hash_word(ptr noundef %word), !dbg !234
    #dbg_value(i32 %call, !235, !DIExpression(DW_OP_constu, 255, DW_OP_and, DW_OP_stack_value), !232)
    #dbg_value(i32 0, !236, !DIExpression(), !238)
  br label %for.body, !dbg !239

for.body:                                         ; preds = %for.inc, %entry
  %index.03.in = phi i32 [ %call, %entry ], [ %add, %for.inc ]
  %probe.02 = phi i32 [ 0, %entry ], [ %inc, %for.inc ]
  %index.03 = and i32 %index.03.in, 255, !dbg !232
    #dbg_value(i32 %probe.02, !236, !DIExpression(), !238)
  %idxprom = zext nneg i32 %index.03 to i64, !dbg !240
  %arrayidx = getelementptr inbounds nuw %struct.entry, ptr %table, i64 %idxprom, !dbg !240
    #dbg_value(ptr %arrayidx, !243, !DIExpression(), !244)
  %count = getelementptr inbounds nuw i8, ptr %arrayidx, i64 24, !dbg !245
  %0 = load i32, ptr %count, align 4, !dbg !245
  %cmp1 = icmp eq i32 %0, 0, !dbg !247
  br i1 %cmp1, label %return, label %if.end, !dbg !247

if.end:                                           ; preds = %for.body
  %call3 = call i32 @strcmp(ptr noundef nonnull dereferenceable(1) %arrayidx, ptr noundef nonnull dereferenceable(1) %word) #10, !dbg !248
  %cmp4 = icmp eq i32 %call3, 0, !dbg !250
  br i1 %cmp4, label %return, label %for.inc, !dbg !250

for.inc:                                          ; preds = %if.end
    #dbg_value(i32 poison, !235, !DIExpression(), !232)
  %add = add nuw nsw i32 %index.03, 1, !dbg !251
    #dbg_value(i32 %add, !235, !DIExpression(DW_OP_constu, 255, DW_OP_and, DW_OP_stack_value), !232)
  %inc = add nuw nsw i32 %probe.02, 1, !dbg !252
    #dbg_value(i32 %inc, !236, !DIExpression(), !238)
    #dbg_value(i32 %add, !235, !DIExpression(DW_OP_constu, 255, DW_OP_and, DW_OP_stack_value), !232)
  %exitcond.not = icmp eq i32 %inc, 256, !dbg !253
  br i1 %exitcond.not, label %return, label %for.body, !dbg !239, !llvm.loop !254

return:                                           ; preds = %for.inc, %if.end, %for.body
  %retval.0 = phi i32 [ 0, %for.body ], [ 0, %for.inc ], [ %0, %if.end ], !dbg !232
  ret i32 %retval.0, !dbg !256
}

declare i32 @printf(ptr noundef, ...) #1

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr writeonly captures(none), i8, i64, i1 immarg) #2

; Function Attrs: noinline nounwind uwtable
define internal i32 @next_word(ptr noundef %text, ptr noundef %word) #0 !dbg !257 {
entry:
    #dbg_value(ptr %text, !262, !DIExpression(), !263)
    #dbg_value(ptr %word, !264, !DIExpression(), !263)
  %0 = load ptr, ptr %text, align 8, !dbg !265
    #dbg_value(ptr %0, !266, !DIExpression(), !263)
  %1 = load i8, ptr %0, align 1, !dbg !267
  %cmp.not1 = icmp eq i8 %1, 0, !dbg !268
  br i1 %cmp.not1, label %while.end, label %land.rhs.lr.ph, !dbg !269

land.rhs.lr.ph:                                   ; preds = %entry
  %call = call ptr @__ctype_b_loc() #11, !dbg !263
  %2 = load ptr, ptr %call, align 8
  br label %land.rhs, !dbg !269

land.rhs:                                         ; preds = %while.body, %land.rhs.lr.ph
  %3 = phi i8 [ %1, %land.rhs.lr.ph ], [ %6, %while.body ]
  %p.02 = phi ptr [ %0, %land.rhs.lr.ph ], [ %incdec.ptr, %while.body ]
    #dbg_value(ptr %p.02, !266, !DIExpression(), !263)
  %idxprom = zext i8 %3 to i64, !dbg !270
  %arrayidx = getelementptr inbounds nuw i16, ptr %2, i64 %idxprom, !dbg !270
  %4 = load i16, ptr %arrayidx, align 2, !dbg !270
  %5 = and i16 %4, 1024, !dbg !270
  %tobool.not = icmp eq i16 %5, 0, !dbg !271
  br i1 %tobool.not, label %while.body, label %while.end, !dbg !272

while.body:                                       ; preds = %land.rhs
  %incdec.ptr = getelementptr inbounds nuw i8, ptr %p.02, i64 1, !dbg !273
    #dbg_value(ptr %incdec.ptr, !266, !DIExpression(), !263)
  %6 = load i8, ptr %incdec.ptr, align 1, !dbg !267
  %cmp.not = icmp eq i8 %6, 0, !dbg !268
  br i1 %cmp.not, label %while.end, label %land.rhs, !dbg !269, !llvm.loop !275

while.end:                                        ; preds = %land.rhs, %while.body, %entry
  %p.0.lcssa = phi ptr [ %0, %entry ], [ %incdec.ptr, %while.body ], [ %p.02, %land.rhs ], !dbg !263
  %.lcssa = phi i8 [ %1, %entry ], [ %6, %while.body ], [ %3, %land.rhs ], !dbg !267
    #dbg_value(i32 0, !277, !DIExpression(), !263)
    #dbg_value(ptr %p.0.lcssa, !266, !DIExpression(), !263)
  %call5 = call ptr @__ctype_b_loc() #11, !dbg !278
  %7 = load ptr, ptr %call5, align 8, !dbg !278
  %idxprom76 = zext i8 %.lcssa to i64, !dbg !278
  %arrayidx87 = getelementptr inbounds nuw i16, ptr %7, i64 %idxprom76, !dbg !278
  %8 = load i16, ptr %arrayidx87, align 2, !dbg !278
  %9 = and i16 %8, 1024, !dbg !278
  %tobool11.not8 = icmp eq i16 %9, 0, !dbg !279
  br i1 %tobool11.not8, label %while.end21, label %while.body12, !dbg !279

while.body12:                                     ; preds = %while.end, %if.end
  %length.010 = phi i32 [ %length.1, %if.end ], [ 0, %while.end ]
  %p.19 = phi ptr [ %incdec.ptr20, %if.end ], [ %p.0.lcssa, %while.end ]
  %10 = phi i8 [ %.pre, %if.end ], [ %.lcssa, %while.end ]
    #dbg_value(i32 %length.010, !277, !DIExpression(), !263)
    #dbg_value(ptr %p.19, !266, !DIExpression(), !263)
  %cmp13 = icmp slt i32 %length.010, 23, !dbg !280
  br i1 %cmp13, label %if.then, label %if.end, !dbg !280

if.then:                                          ; preds = %while.body12
  %conv15 = zext i8 %10 to i32, !dbg !283
  %call16 = call i32 @tolower(i32 noundef %conv15) #10, !dbg !285
  %conv17 = trunc i32 %call16 to i8, !dbg !286
  %inc = add nsw i32 %length.010, 1, !dbg !287
    #dbg_value(i32 %inc, !277, !DIExpression(), !263)
  %idxprom18 = sext i32 %length.010 to i64, !dbg !288
  %arrayidx19 = getelementptr inbounds i8, ptr %word, i64 %idxprom18, !dbg !288
  store i8 %conv17, ptr %arrayidx19, align 1, !dbg !289
  br label %if.end, !dbg !290

if.end:                                           ; preds = %if.then, %while.body12
  %length.1 = phi i32 [ %inc, %if.then ], [ %length.010, %while.body12 ], !dbg !263
    #dbg_value(i32 %length.1, !277, !DIExpression(), !263)
  %incdec.ptr20 = getelementptr inbounds nuw i8, ptr %p.19, i64 1, !dbg !291
    #dbg_value(ptr %incdec.ptr20, !266, !DIExpression(), !263)
  %.pre = load i8, ptr %incdec.ptr20, align 1, !dbg !292
  %11 = load ptr, ptr %call5, align 8, !dbg !278
  %idxprom7 = zext i8 %.pre to i64, !dbg !278
  %arrayidx8 = getelementptr inbounds nuw i16, ptr %11, i64 %idxprom7, !dbg !278
  %12 = load i16, ptr %arrayidx8, align 2, !dbg !278
  %13 = and i16 %12, 1024, !dbg !278
  %tobool11.not = icmp eq i16 %13, 0, !dbg !279
  br i1 %tobool11.not, label %while.end21, label %while.body12, !dbg !279, !llvm.loop !293

while.end21:                                      ; preds = %if.end, %while.end
  %p.1.lcssa = phi ptr [ %p.0.lcssa, %while.end ], [ %incdec.ptr20, %if.end ], !dbg !263
  %length.0.lcssa = phi i32 [ 0, %while.end ], [ %length.1, %if.end ], !dbg !263
  %idxprom22 = sext i32 %length.0.lcssa to i64, !dbg !295
  %arrayidx23 = getelementptr inbounds i8, ptr %word, i64 %idxprom22, !dbg !295
  store i8 0, ptr %arrayidx23, align 1, !dbg !296
  store ptr %p.1.lcssa, ptr %text, align 8, !dbg !297
  ret i32 %length.0.lcssa, !dbg !298
}

; Function Attrs: noinline nounwind uwtable
define internal i32 @table_add(ptr noundef %table, ptr noundef %word, i32 noundef %position) #0 !dbg !299 {
entry:
    #dbg_value(ptr %table, !302, !DIExpression(), !303)
    #dbg_value(ptr %word, !304, !DIExpression(), !303)
    #dbg_value(i32 %position, !305, !DIExpression(), !303)
  %call = call i32 @hash_word(ptr noundef %word), !dbg !306
    #dbg_value(i32 %call, !307, !DIExpression(DW_OP_constu, 255, DW_OP_and, DW_OP_stack_value), !303)
    #dbg_value(i32 0, !308, !DIExpression(), !310)
  br label %for.body, !dbg !311

for.body:                                         ; preds = %for.inc, %entry
  %index.03.in = phi i32 [ %call, %entry ], [ %add, %for.inc ]
  %probe.02 = phi i32 [ 0, %entry ], [ %inc14, %for.inc ]
  %index.03 = and i32 %index.03.in, 255, !dbg !303
    #dbg_value(i32 %probe.02, !308, !DIExpression(), !310)
  %idxprom = zext nneg i32 %index.03 to i64, !dbg !312
  %arrayidx = getelementptr inbounds nuw %struct.entry, ptr %table, i64 %idxprom, !dbg !312
    #dbg_value(ptr %arrayidx, !315, !DIExpression(), !316)
  %count = getelementptr inbounds nuw i8, ptr %arrayidx, i64 24, !dbg !317
  %0 = load i32, ptr %count, align 4, !dbg !317
  %cmp1 = icmp eq i32 %0, 0, !dbg !319
  br i1 %cmp1, label %if.then, label %if.end, !dbg !319

if.then:                                          ; preds = %for.body
  %count.le2 = getelementptr inbounds nuw i8, ptr %arrayidx, i64 24
  %call3 = call ptr @strncpy(ptr noundef nonnull dereferenceable(1) %arrayidx, ptr noundef nonnull dereferenceable(1) %word, i64 noundef 23) #8, !dbg !320
  store i32 1, ptr %count.le2, align 4, !dbg !322
  %first_seen = getelementptr inbounds nuw i8, ptr %arrayidx, i64 28, !dbg !323
  store i32 %position, ptr %first_seen, align 4, !dbg !324
  %used = getelementptr inbounds nuw i8, ptr %table, i64 8192, !dbg !325
  %1 = load i32, ptr %used, align 4, !dbg !326
  %inc = add nsw i32 %1, 1, !dbg !326
  store i32 %inc, ptr %used, align 4, !dbg !326
  br label %return, !dbg !327

if.end:                                           ; preds = %for.body
  %call7 = call i32 @strcmp(ptr noundef nonnull dereferenceable(1) %arrayidx, ptr noundef nonnull dereferenceable(1) %word) #10, !dbg !328
  %cmp8 = icmp eq i32 %call7, 0, !dbg !330
  br i1 %cmp8, label %if.then9, label %for.inc, !dbg !330

if.then9:                                         ; preds = %if.end
  %count.le = getelementptr inbounds nuw i8, ptr %arrayidx, i64 24
  %inc11 = add nsw i32 %0, 1, !dbg !331
  store i32 %inc11, ptr %count.le, align 4, !dbg !331
  br label %return, !dbg !333

for.inc:                                          ; preds = %if.end
    #dbg_value(i32 poison, !307, !DIExpression(), !303)
  %add = add nuw nsw i32 %index.03, 1, !dbg !334
    #dbg_value(i32 %add, !307, !DIExpression(DW_OP_constu, 255, DW_OP_and, DW_OP_stack_value), !303)
  %inc14 = add nuw nsw i32 %probe.02, 1, !dbg !335
    #dbg_value(i32 %inc14, !308, !DIExpression(), !310)
    #dbg_value(i32 %add, !307, !DIExpression(DW_OP_constu, 255, DW_OP_and, DW_OP_stack_value), !303)
  %exitcond.not = icmp eq i32 %inc14, 256, !dbg !336
  br i1 %exitcond.not, label %return, label %for.body, !dbg !311, !llvm.loop !337

return:                                           ; preds = %for.inc, %if.then9, %if.then
  %retval.0 = phi i32 [ 1, %if.then ], [ 0, %if.then9 ], [ -1, %for.inc ], !dbg !303
  ret i32 %retval.0, !dbg !339
}

; Function Attrs: nounwind
declare i32 @fprintf(ptr noundef, ptr noundef, ...) #3

; Function Attrs: nounwind willreturn memory(none)
declare ptr @__ctype_b_loc() #4

; Function Attrs: nounwind willreturn memory(read)
declare i32 @tolower(i32 noundef) #5

; Function Attrs: noinline nounwind uwtable
define internal i32 @hash_word(ptr noundef %word) #0 !dbg !340 {
entry:
    #dbg_value(ptr %word, !343, !DIExpression(), !344)
    #dbg_value(i32 -2128831035, !345, !DIExpression(), !344)
    #dbg_value(ptr %word, !346, !DIExpression(), !348)
  %0 = load i8, ptr %word, align 1, !dbg !349
  %cmp.not1 = icmp eq i8 %0, 0, !dbg !351
  br i1 %cmp.not1, label %for.end, label %for.inc, !dbg !352

for.inc:                                          ; preds = %entry, %for.inc
  %1 = phi i8 [ %2, %for.inc ], [ %0, %entry ]
  %p.03 = phi ptr [ %incdec.ptr, %for.inc ], [ %word, %entry ]
  %hash.02 = phi i32 [ %mul, %for.inc ], [ -2128831035, %entry ]
    #dbg_value(ptr %p.03, !346, !DIExpression(), !348)
    #dbg_value(!DIArgList(i32 %hash.02, i8 %1), !345, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_LLVM_convert, 32, DW_ATE_unsigned, DW_OP_xor, DW_OP_constu, 16777619, DW_OP_mul, DW_OP_stack_value), !344)
  %conv2 = zext i8 %1 to i32, !dbg !353
    #dbg_value(!DIArgList(i32 %hash.02, i32 %conv2), !345, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_xor, DW_OP_constu, 16777619, DW_OP_mul, DW_OP_stack_value), !344)
  %xor = xor i32 %hash.02, %conv2, !dbg !355
    #dbg_value(i32 %xor, !345, !DIExpression(DW_OP_constu, 16777619, DW_OP_mul, DW_OP_stack_value), !344)
  %mul = mul i32 %xor, 16777619, !dbg !356
    #dbg_value(i32 %mul, !345, !DIExpression(), !344)
  %incdec.ptr = getelementptr inbounds nuw i8, ptr %p.03, i64 1, !dbg !357
    #dbg_value(ptr %incdec.ptr, !346, !DIExpression(), !348)
  %2 = load i8, ptr %incdec.ptr, align 1, !dbg !349
  %cmp.not = icmp eq i8 %2, 0, !dbg !351
  br i1 %cmp.not, label %for.end, label %for.inc, !dbg !352, !llvm.loop !358

for.end:                                          ; preds = %for.inc, %entry
  %hash.0.lcssa = phi i32 [ -2128831035, %entry ], [ %mul, %for.inc ], !dbg !344
  ret i32 %hash.0.lcssa, !dbg !360
}

; Function Attrs: nounwind
declare ptr @strncpy(ptr noundef, ptr noundef, i64 noundef) #3

; Function Attrs: nounwind willreturn memory(read)
declare i32 @strcmp(ptr noundef, ptr noundef) #5

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #6

declare void @qsort(ptr noundef, i64 noundef, i64 noundef, ptr noundef) #1

; Function Attrs: noinline nounwind uwtable
define internal i32 @by_count(ptr noundef %a, ptr noundef %b) #0 !dbg !361 {
entry:
    #dbg_value(ptr %a, !366, !DIExpression(), !367)
    #dbg_value(ptr %b, !368, !DIExpression(), !367)
    #dbg_value(ptr %a, !369, !DIExpression(), !367)
    #dbg_value(ptr %b, !370, !DIExpression(), !367)
  %count = getelementptr inbounds nuw i8, ptr %a, i64 24, !dbg !371
  %0 = load i32, ptr %count, align 4, !dbg !371
  %count1 = getelementptr inbounds nuw i8, ptr %b, i64 24, !dbg !373
  %1 = load i32, ptr %count1, align 4, !dbg !373
  %cmp.not = icmp eq i32 %0, %1, !dbg !374
  br i1 %cmp.not, label %if.end, label %if.then, !dbg !374

if.then:                                          ; preds = %entry
  %sub = sub nsw i32 %1, %0, !dbg !375
  br label %return, !dbg !377

if.end:                                           ; preds = %entry
  %first_seen = getelementptr inbounds nuw i8, ptr %a, i64 28, !dbg !378
  %2 = load i32, ptr %first_seen, align 4, !dbg !378
  %first_seen4 = getelementptr inbounds nuw i8, ptr %b, i64 28, !dbg !379
  %3 = load i32, ptr %first_seen4, align 4, !dbg !379
  %sub5 = sub nsw i32 %2, %3, !dbg !380
  br label %return, !dbg !381

return:                                           ; preds = %if.end, %if.then
  %retval.0 = phi i32 [ %sub, %if.then ], [ %sub5, %if.end ], !dbg !367
  ret i32 %retval.0, !dbg !382
}

; Function Attrs: noinline nounwind uwtable
define internal void @print_bar(i32 noundef %count, i32 noundef %widest) #0 !dbg !383 {
entry:
    #dbg_value(i32 %count, !386, !DIExpression(), !387)
    #dbg_value(i32 %widest, !388, !DIExpression(), !387)
  %cmp = icmp sgt i32 %widest, 0, !dbg !389
  br i1 %cmp, label %cond.true, label %cond.end, !dbg !390

cond.true:                                        ; preds = %entry
  %mul = mul nsw i32 %count, 30, !dbg !391
  %div = sdiv i32 %mul, %widest, !dbg !392
  br label %cond.end, !dbg !390

cond.end:                                         ; preds = %cond.true, %entry
  %cond = phi i32 [ %div, %cond.true ], [ 0, %entry ], !dbg !390
    #dbg_value(i32 %cond, !393, !DIExpression(), !387)
    #dbg_value(i32 0, !394, !DIExpression(), !396)
  %cmp11 = icmp sgt i32 %cond, 0, !dbg !397
  br i1 %cmp11, label %for.body, label %for.end, !dbg !399

for.body:                                         ; preds = %cond.end, %for.body
  %i.02 = phi i32 [ %inc, %for.body ], [ 0, %cond.end ]
    #dbg_value(i32 %i.02, !394, !DIExpression(), !396)
  %call = call i32 @putchar(i32 noundef 35) #8, !dbg !400
  %inc = add nuw nsw i32 %i.02, 1, !dbg !402
    #dbg_value(i32 %inc, !394, !DIExpression(), !396)
  %exitcond.not = icmp eq i32 %inc, %cond, !dbg !397
  br i1 %exitcond.not, label %for.end, label %for.body, !dbg !399, !llvm.loop !403

for.end:                                          ; preds = %for.body, %cond.end
  %call2 = call i32 @putchar(i32 noundef 10) #8, !dbg !405
  ret void, !dbg !406
}

; Function Attrs: noinline nounwind uwtable
define internal ptr @longest(ptr noundef %entries, i32 noundef %n) #0 !dbg !407 {
entry:
    #dbg_value(ptr %entries, !410, !DIExpression(), !411)
    #dbg_value(i32 %n, !412, !DIExpression(), !411)
    #dbg_value(ptr null, !413, !DIExpression(), !411)
    #dbg_value(i64 0, !414, !DIExpression(), !411)
    #dbg_value(i32 0, !415, !DIExpression(), !417)
  %cmp2 = icmp sgt i32 %n, 0, !dbg !418
  br i1 %cmp2, label %for.body.lr.ph, label %for.end, !dbg !420

for.body.lr.ph:                                   ; preds = %entry
  %wide.trip.count = zext nneg i32 %n to i64, !dbg !418
  br label %for.body, !dbg !420

for.body:                                         ; preds = %for.body, %for.body.lr.ph
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.body ], [ 0, %for.body.lr.ph ]
  %best_length.04 = phi i64 [ %best_length.1, %for.body ], [ 0, %for.body.lr.ph ]
  %best.03 = phi ptr [ %best.1, %for.body ], [ null, %for.body.lr.ph ]
    #dbg_value(i64 %indvars.iv, !415, !DIExpression(), !417)
    #dbg_value(i64 %best_length.04, !414, !DIExpression(), !411)
    #dbg_value(ptr %best.03, !413, !DIExpression(), !411)
  %arrayidx = getelementptr inbounds nuw %struct.entry, ptr %entries, i64 %indvars.iv, !dbg !421
  %call = call i64 @strlen(ptr noundef nonnull dereferenceable(1) %arrayidx) #10, !dbg !423
    #dbg_value(i64 %call, !424, !DIExpression(), !425)
  %cmp1 = icmp ugt i64 %call, %best_length.04, !dbg !426
  %best.1 = select i1 %cmp1, ptr %arrayidx, ptr %best.03, !dbg !426
  %best_length.1 = call i64 @llvm.umax.i64(i64 %call, i64 %best_length.04), !dbg !426
    #dbg_value(i64 %best_length.1, !414, !DIExpression(), !411)
    #dbg_value(ptr %best.1, !413, !DIExpression(), !411)
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1, !dbg !428
    #dbg_value(i64 %indvars.iv.next, !415, !DIExpression(), !417)
  %exitcond.not = icmp eq i64 %indvars.iv.next, %wide.trip.count, !dbg !418
  br i1 %exitcond.not, label %for.end, label %for.body, !dbg !420, !llvm.loop !429

for.end:                                          ; preds = %for.body, %entry
  %best.0.lcssa = phi ptr [ null, %entry ], [ %best.1, %for.body ], !dbg !411
  ret ptr %best.0.lcssa, !dbg !431
}

; Function Attrs: noinline nounwind uwtable
define internal double @mean_length(ptr noundef %entries, i32 noundef %n) #0 !dbg !432 {
entry:
    #dbg_value(ptr %entries, !435, !DIExpression(), !436)
    #dbg_value(i32 %n, !437, !DIExpression(), !436)
    #dbg_value(i64 0, !438, !DIExpression(), !436)
    #dbg_value(i64 0, !439, !DIExpression(), !436)
    #dbg_value(i32 0, !440, !DIExpression(), !442)
  %cmp1 = icmp sgt i32 %n, 0, !dbg !443
  br i1 %cmp1, label %for.inc.lr.ph, label %for.end, !dbg !445

for.inc.lr.ph:                                    ; preds = %entry
  %wide.trip.count = zext nneg i32 %n to i64, !dbg !443
  br label %for.inc, !dbg !445

for.inc:                                          ; preds = %for.inc, %for.inc.lr.ph
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 0, %for.inc.lr.ph ]
  %words.03 = phi i64 [ %add7, %for.inc ], [ 0, %for.inc.lr.ph ]
  %letters.02 = phi i64 [ %add, %for.inc ], [ 0, %for.inc.lr.ph ]
    #dbg_value(i64 %indvars.iv, !440, !DIExpression(), !442)
    #dbg_value(!DIArgList(i64 poison, i64 poison, i32 poison), !438, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_LLVM_arg, 2, DW_OP_LLVM_convert, 32, DW_ATE_signed, DW_OP_LLVM_convert, 64, DW_ATE_signed, DW_OP_mul, DW_OP_plus, DW_OP_stack_value), !436)
    #dbg_value(!DIArgList(i64 poison, i32 poison), !439, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_LLVM_convert, 32, DW_ATE_signed, DW_OP_LLVM_convert, 64, DW_ATE_signed, DW_OP_plus, DW_OP_stack_value), !436)
  %arrayidx4 = getelementptr inbounds nuw %struct.entry, ptr %entries, i64 %indvars.iv, !dbg !446
  %count5 = getelementptr inbounds nuw i8, ptr %arrayidx4, i64 24, !dbg !448
  %0 = load i32, ptr %count5, align 4, !dbg !448
    #dbg_value(!DIArgList(i64 %words.03, i32 %0), !439, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_LLVM_convert, 32, DW_ATE_signed, DW_OP_LLVM_convert, 64, DW_ATE_signed, DW_OP_plus, DW_OP_stack_value), !436)
  %conv6 = sext i32 %0 to i64, !dbg !446
    #dbg_value(!DIArgList(i64 %words.03, i64 %conv6), !439, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_plus, DW_OP_stack_value), !436)
  %add7 = add nsw i64 %words.03, %conv6, !dbg !449
    #dbg_value(i64 %add7, !439, !DIExpression(), !436)
  %call = call i64 @strlen(ptr noundef nonnull dereferenceable(1) %arrayidx4) #10, !dbg !450
    #dbg_value(!DIArgList(i64 %letters.02, i64 %call, i64 %conv6), !438, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_LLVM_arg, 2, DW_OP_mul, DW_OP_plus, DW_OP_stack_value), !436)
  %mul = mul nsw i64 %call, %conv6, !dbg !451
    #dbg_value(!DIArgList(i64 %letters.02, i64 %mul), !438, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_plus, DW_OP_stack_value), !436)
  %add = add nsw i64 %letters.02, %mul, !dbg !452
    #dbg_value(i64 %add, !438, !DIExpression(), !436)
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1, !dbg !453
    #dbg_value(i64 %indvars.iv.next, !440, !DIExpression(), !442)
  %exitcond.not = icmp eq i64 %indvars.iv.next, %wide.trip.count, !dbg !443
  br i1 %exitcond.not, label %for.cond.for.end_crit_edge, label %for.inc, !dbg !445, !llvm.loop !454

for.cond.for.end_crit_edge:                       ; preds = %for.inc
  %1 = sitofp i64 %add to double, !dbg !456
  br label %for.end, !dbg !445

for.end:                                          ; preds = %for.cond.for.end_crit_edge, %entry
  %letters.0.lcssa = phi double [ %1, %for.cond.for.end_crit_edge ], [ 0.000000e+00, %entry ], !dbg !436
  %words.0.lcssa = phi i64 [ %add7, %for.cond.for.end_crit_edge ], [ 0, %entry ], !dbg !436
  %cmp8 = icmp sgt i64 %words.0.lcssa, 0, !dbg !457
  %conv11 = sitofp i64 %words.0.lcssa to double, !dbg !456
  %div = fdiv double %letters.0.lcssa, %conv11, !dbg !456
  %cond = select i1 %cmp8, double %div, double 0.000000e+00, !dbg !456
  ret double %cond, !dbg !458
}

; Function Attrs: noinline nounwind uwtable
define internal i32 @singletons(ptr noundef %entries, i32 noundef %n) #0 !dbg !459 {
entry:
    #dbg_value(ptr %entries, !462, !DIExpression(), !463)
    #dbg_value(i32 %n, !464, !DIExpression(), !463)
    #dbg_value(i32 0, !465, !DIExpression(), !463)
    #dbg_value(i32 %n, !466, !DIExpression(DW_OP_constu, 1, DW_OP_minus, DW_OP_stack_value), !468)
  %cmp3 = icmp sgt i32 %n, 0, !dbg !469
  br i1 %cmp3, label %land.rhs.lr.ph, label %for.end, !dbg !471

land.rhs.lr.ph:                                   ; preds = %entry
  %0 = zext nneg i32 %n to i64, !dbg !471
  br label %land.rhs, !dbg !471

land.rhs:                                         ; preds = %for.inc, %land.rhs.lr.ph
  %indvars.iv.in = phi i64 [ %indvars.iv, %for.inc ], [ %0, %land.rhs.lr.ph ]
  %count.04 = phi i32 [ %inc, %for.inc ], [ 0, %land.rhs.lr.ph ]
  %indvars.iv = add nsw i64 %indvars.iv.in, -1, !dbg !472
    #dbg_value(i32 %count.04, !465, !DIExpression(), !463)
  %arrayidx = getelementptr inbounds %struct.entry, ptr %entries, i64 %indvars.iv, !dbg !473
  %count1 = getelementptr inbounds nuw i8, ptr %arrayidx, i64 24, !dbg !474
  %1 = load i32, ptr %count1, align 4, !dbg !474
  %cmp2 = icmp eq i32 %1, 1, !dbg !475
  br i1 %cmp2, label %for.inc, label %for.end, !dbg !476

for.inc:                                          ; preds = %land.rhs
    #dbg_value(i32 %count.04, !465, !DIExpression(DW_OP_plus_uconst, 1, DW_OP_stack_value), !463)
  %inc = add nuw i32 %count.04, 1, !dbg !477
    #dbg_value(i32 %inc, !465, !DIExpression(), !463)
    #dbg_value(i64 %indvars.iv, !466, !DIExpression(DW_OP_constu, 1, DW_OP_minus, DW_OP_stack_value), !468)
    #dbg_value(i64 %indvars.iv, !466, !DIExpression(DW_OP_constu, 1, DW_OP_minus, DW_OP_stack_value), !468)
  %exitcond.not = icmp eq i32 %inc, %n, !dbg !469
  br i1 %exitcond.not, label %for.end, label %land.rhs, !dbg !471, !llvm.loop !479

for.end:                                          ; preds = %land.rhs, %for.inc, %entry
  %count.0.lcssa = phi i32 [ 0, %entry ], [ %n, %for.inc ], [ %count.04, %land.rhs ], !dbg !463
  ret i32 %count.0.lcssa, !dbg !481
}

declare i32 @putchar(i32 noundef) #1

; Function Attrs: nounwind willreturn memory(read)
declare i64 @strlen(ptr noundef) #5

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.smin.i32(i32, i32) #7

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare i64 @llvm.umax.i64(i64, i64) #7

attributes #0 = { noinline nounwind uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #3 = { nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind willreturn memory(none) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #5 = { nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #6 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #7 = { nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none) }
attributes #8 = { nounwind }
attributes #9 = { cold nounwind }
attributes #10 = { nounwind willreturn memory(read) }
attributes #11 = { nounwind willreturn memory(none) }

!llvm.dbg.cu = !{!7}
!llvm.module.flags = !{!100, !101, !102, !103, !104, !105, !106}
!llvm.ident = !{!107}

!0 = !DIGlobalVariableExpression(var: !1, expr: !DIExpression())
!1 = distinct !DIGlobalVariable(name: "table", scope: !2, file: !3, line: 186, type: !96, isLocal: true, isDefinition: true)
!2 = distinct !DISubprogram(name: "main", scope: !3, file: !3, line: 185, type: !4, scopeLine: 185, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !7, retainedNodes: !95)
!3 = !DIFile(filename: "user-programs/word_frequency.c", directory: "/workspace", checksumkind: CSK_MD5, checksum: "afd9b995c56306632b4c51ff31edd173")
!4 = !DISubroutineType(types: !5)
!5 = !{!6}
!6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!7 = distinct !DICompileUnit(language: DW_LANG_C11, file: !8, producer: "clang version 22.1.8 (https://github.com/llvm/llvm-project ca7933e47d3a3451d81e72ac174dcb5aa28b59d1)", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, enums: !9, retainedTypes: !26, globals: !36, splitDebugInlining: false, nameTableKind: None)
!8 = !DIFile(filename: "/workspace/user-programs/word_frequency.c", directory: "/workspace", checksumkind: CSK_MD5, checksum: "afd9b995c56306632b4c51ff31edd173")
!9 = !{!10}
!10 = !DICompositeType(tag: DW_TAG_enumeration_type, file: !11, line: 46, baseType: !12, size: 32, elements: !13)
!11 = !DIFile(filename: "/usr/include/ctype.h", directory: "", checksumkind: CSK_MD5, checksum: "43fd45dcf96e8fb7d8f14700096497c7")
!12 = !DIBasicType(name: "unsigned int", size: 32, encoding: DW_ATE_unsigned)
!13 = !{!14, !15, !16, !17, !18, !19, !20, !21, !22, !23, !24, !25}
!14 = !DIEnumerator(name: "_ISupper", value: 256)
!15 = !DIEnumerator(name: "_ISlower", value: 512)
!16 = !DIEnumerator(name: "_ISalpha", value: 1024)
!17 = !DIEnumerator(name: "_ISdigit", value: 2048)
!18 = !DIEnumerator(name: "_ISxdigit", value: 4096)
!19 = !DIEnumerator(name: "_ISspace", value: 8192)
!20 = !DIEnumerator(name: "_ISprint", value: 16384)
!21 = !DIEnumerator(name: "_ISgraph", value: 32768)
!22 = !DIEnumerator(name: "_ISblank", value: 1)
!23 = !DIEnumerator(name: "_IScntrl", value: 2)
!24 = !DIEnumerator(name: "_ISpunct", value: 4)
!25 = !DIEnumerator(name: "_ISalnum", value: 8)
!26 = !{!6, !27, !28, !29, !30, !33, !34, !35}
!27 = !DIBasicType(name: "unsigned char", size: 8, encoding: DW_ATE_unsigned_char)
!28 = !DIBasicType(name: "unsigned short", size: 16, encoding: DW_ATE_unsigned)
!29 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!30 = !DIDerivedType(tag: DW_TAG_typedef, name: "size_t", file: !31, line: 18, baseType: !32)
!31 = !DIFile(filename: "/opt/llvm/lib/clang/22/include/__stddef_size_t.h", directory: "", checksumkind: CSK_MD5, checksum: "2c44e821a2b1951cde2eb0fb2e656867")
!32 = !DIBasicType(name: "unsigned long", size: 64, encoding: DW_ATE_unsigned)
!33 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
!34 = !DIBasicType(name: "long", size: 64, encoding: DW_ATE_signed)
!35 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!36 = !{!0, !37, !50, !55, !57, !62, !67, !72, !76, !78, !83, !85, !90}
!37 = !DIGlobalVariableExpression(var: !38, expr: !DIExpression())
!38 = distinct !DIGlobalVariable(name: "entries", scope: !2, file: !3, line: 187, type: !39, isLocal: true, isDefinition: true)
!39 = !DICompositeType(tag: DW_TAG_array_type, baseType: !40, size: 65536, elements: !48)
!40 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "entry", file: !3, line: 12, size: 256, elements: !41)
!41 = !{!42, !46, !47}
!42 = !DIDerivedType(tag: DW_TAG_member, name: "word", scope: !40, file: !3, line: 13, baseType: !43, size: 192)
!43 = !DICompositeType(tag: DW_TAG_array_type, baseType: !29, size: 192, elements: !44)
!44 = !{!45}
!45 = !DISubrange(count: 24)
!46 = !DIDerivedType(tag: DW_TAG_member, name: "count", scope: !40, file: !3, line: 14, baseType: !6, size: 32, offset: 192)
!47 = !DIDerivedType(tag: DW_TAG_member, name: "first_seen", scope: !40, file: !3, line: 15, baseType: !6, size: 32, offset: 224)
!48 = !{!49}
!49 = !DISubrange(count: 256)
!50 = !DIGlobalVariableExpression(var: !51, expr: !DIExpression())
!51 = distinct !DIGlobalVariable(scope: null, file: !3, line: 192, type: !52, isLocal: true, isDefinition: true)
!52 = !DICompositeType(tag: DW_TAG_array_type, baseType: !29, size: 32, elements: !53)
!53 = !{!54}
!54 = !DISubrange(count: 4)
!55 = !DIGlobalVariableExpression(var: !56, expr: !DIExpression())
!56 = distinct !DIGlobalVariable(scope: null, file: !3, line: 193, type: !52, isLocal: true, isDefinition: true)
!57 = !DIGlobalVariableExpression(var: !58, expr: !DIExpression())
!58 = distinct !DIGlobalVariable(scope: null, file: !3, line: 194, type: !59, isLocal: true, isDefinition: true)
!59 = !DICompositeType(tag: DW_TAG_array_type, baseType: !29, size: 144, elements: !60)
!60 = !{!61}
!61 = !DISubrange(count: 18)
!62 = !DIGlobalVariableExpression(var: !63, expr: !DIExpression())
!63 = distinct !DIGlobalVariable(scope: null, file: !3, line: 102, type: !64, isLocal: true, isDefinition: true)
!64 = !DICompositeType(tag: DW_TAG_array_type, baseType: !29, size: 184, elements: !65)
!65 = !{!66}
!66 = !DISubrange(count: 23)
!67 = !DIGlobalVariableExpression(var: !68, expr: !DIExpression())
!68 = distinct !DIGlobalVariable(scope: null, file: !3, line: 24, type: !69, isLocal: true, isDefinition: true)
!69 = !DICompositeType(tag: DW_TAG_array_type, baseType: !29, size: 2280, elements: !70)
!70 = !{!71}
!71 = !DISubrange(count: 285)
!72 = !DIGlobalVariableExpression(var: !73, expr: !DIExpression())
!73 = distinct !DIGlobalVariable(name: "passage", scope: !7, file: !3, line: 23, type: !74, isLocal: true, isDefinition: true)
!74 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !75, size: 64)
!75 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !29)
!76 = !DIGlobalVariableExpression(var: !77, expr: !DIExpression())
!77 = distinct !DIGlobalVariable(scope: null, file: !3, line: 172, type: !64, isLocal: true, isDefinition: true)
!78 = !DIGlobalVariableExpression(var: !79, expr: !DIExpression())
!79 = distinct !DIGlobalVariable(scope: null, file: !3, line: 174, type: !80, isLocal: true, isDefinition: true)
!80 = !DICompositeType(tag: DW_TAG_array_type, baseType: !29, size: 88, elements: !81)
!81 = !{!82}
!82 = !DISubrange(count: 11)
!83 = !DIGlobalVariableExpression(var: !84, expr: !DIExpression())
!84 = distinct !DIGlobalVariable(scope: null, file: !3, line: 179, type: !59, isLocal: true, isDefinition: true)
!85 = !DIGlobalVariableExpression(var: !86, expr: !DIExpression())
!86 = distinct !DIGlobalVariable(scope: null, file: !3, line: 181, type: !87, isLocal: true, isDefinition: true)
!87 = !DICompositeType(tag: DW_TAG_array_type, baseType: !29, size: 216, elements: !88)
!88 = !{!89}
!89 = !DISubrange(count: 27)
!90 = !DIGlobalVariableExpression(var: !91, expr: !DIExpression())
!91 = distinct !DIGlobalVariable(scope: null, file: !3, line: 182, type: !92, isLocal: true, isDefinition: true)
!92 = !DICompositeType(tag: DW_TAG_array_type, baseType: !29, size: 168, elements: !93)
!93 = !{!94}
!94 = !DISubrange(count: 21)
!95 = !{}
!96 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "table", file: !3, line: 18, size: 65568, elements: !97)
!97 = !{!98, !99}
!98 = !DIDerivedType(tag: DW_TAG_member, name: "slots", scope: !96, file: !3, line: 19, baseType: !39, size: 65536)
!99 = !DIDerivedType(tag: DW_TAG_member, name: "used", scope: !96, file: !3, line: 20, baseType: !6, size: 32, offset: 65536)
!100 = !{i32 7, !"Dwarf Version", i32 5}
!101 = !{i32 2, !"Debug Info Version", i32 3}
!102 = !{i32 1, !"wchar_size", i32 4}
!103 = !{i32 8, !"PIC Level", i32 2}
!104 = !{i32 7, !"PIE Level", i32 2}
!105 = !{i32 7, !"uwtable", i32 2}
!106 = !{i32 7, !"frame-pointer", i32 2}
!107 = !{!"clang version 22.1.8 (https://github.com/llvm/llvm-project ca7933e47d3a3451d81e72ac174dcb5aa28b59d1)"}
!108 = !DILocation(line: 188, column: 5, scope: !2)
!109 = !DILocation(line: 189, column: 37, scope: !2)
!110 = !DILocation(line: 189, column: 17, scope: !2)
!111 = !DILocalVariable(name: "total", scope: !2, file: !3, line: 189, type: !6)
!112 = !DILocation(line: 0, scope: !2)
!113 = !DILocation(line: 190, column: 13, scope: !2)
!114 = !DILocalVariable(name: "n", scope: !2, file: !3, line: 190, type: !6)
!115 = !DILocation(line: 191, column: 5, scope: !2)
!116 = !DILocation(line: 192, column: 17, scope: !2)
!117 = !DILocalVariable(name: "foxes", scope: !2, file: !3, line: 192, type: !6)
!118 = !DILocation(line: 193, column: 16, scope: !2)
!119 = !DILocalVariable(name: "cats", scope: !2, file: !3, line: 193, type: !6)
!120 = !DILocation(line: 194, column: 5, scope: !2)
!121 = !DILocation(line: 195, column: 22, scope: !2)
!122 = !DILocation(line: 195, column: 5, scope: !2)
!123 = distinct !DISubprogram(name: "table_init", scope: !3, file: !3, line: 39, type: !124, scopeLine: 39, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!124 = !DISubroutineType(types: !125)
!125 = !{null, !126}
!126 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !96, size: 64)
!127 = !DILocalVariable(name: "table", arg: 1, scope: !123, file: !3, line: 39, type: !126)
!128 = !DILocation(line: 0, scope: !123)
!129 = !DILocation(line: 40, column: 5, scope: !123)
!130 = !DILocation(line: 41, column: 1, scope: !123)
!131 = distinct !DISubprogram(name: "count_words", scope: !3, file: !3, line: 97, type: !132, scopeLine: 97, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!132 = !DISubroutineType(types: !133)
!133 = !{!6, !126, !74}
!134 = !DILocalVariable(name: "table", arg: 1, scope: !131, file: !3, line: 97, type: !126)
!135 = !DILocation(line: 0, scope: !131)
!136 = !DILocalVariable(name: "text", arg: 2, scope: !131, file: !3, line: 97, type: !74)
!137 = !DILocalVariable(name: "word", scope: !131, file: !3, line: 98, type: !43)
!138 = !DILocation(line: 98, column: 10, scope: !131)
!139 = !DILocalVariable(name: "position", scope: !131, file: !3, line: 99, type: !6)
!140 = !DILocation(line: 100, column: 12, scope: !131)
!141 = !DILocation(line: 100, column: 35, scope: !131)
!142 = !DILocation(line: 100, column: 5, scope: !131)
!143 = !DILocation(line: 101, column: 13, scope: !144)
!144 = distinct !DILexicalBlock(scope: !145, file: !3, line: 101, column: 13)
!145 = distinct !DILexicalBlock(scope: !131, file: !3, line: 100, column: 40)
!146 = !DILocation(line: 101, column: 46, scope: !144)
!147 = !DILocation(line: 102, column: 21, scope: !148)
!148 = distinct !DILexicalBlock(scope: !144, file: !3, line: 101, column: 51)
!149 = !DILocation(line: 102, column: 13, scope: !148)
!150 = !DILocation(line: 103, column: 13, scope: !148)
!151 = !DILocation(line: 105, column: 17, scope: !145)
!152 = distinct !{!152, !142, !153, !154}
!153 = !DILocation(line: 106, column: 5, scope: !131)
!154 = !{!"llvm.loop.mustprogress"}
!155 = !DILocation(line: 107, column: 5, scope: !131)
!156 = distinct !DISubprogram(name: "collect", scope: !3, file: !3, line: 120, type: !157, scopeLine: 120, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!157 = !DISubroutineType(types: !158)
!158 = !{!6, !159, !161}
!159 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !160, size: 64)
!160 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !96)
!161 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !40, size: 64)
!162 = !DILocalVariable(name: "table", arg: 1, scope: !156, file: !3, line: 120, type: !159)
!163 = !DILocation(line: 0, scope: !156)
!164 = !DILocalVariable(name: "out", arg: 2, scope: !156, file: !3, line: 120, type: !161)
!165 = !DILocalVariable(name: "n", scope: !156, file: !3, line: 121, type: !6)
!166 = !DILocalVariable(name: "i", scope: !167, file: !3, line: 122, type: !6)
!167 = distinct !DILexicalBlock(scope: !156, file: !3, line: 122, column: 5)
!168 = !DILocation(line: 0, scope: !167)
!169 = !DILocation(line: 122, column: 5, scope: !167)
!170 = !DILocation(line: 123, column: 13, scope: !171)
!171 = distinct !DILexicalBlock(scope: !172, file: !3, line: 123, column: 13)
!172 = distinct !DILexicalBlock(scope: !173, file: !3, line: 122, column: 42)
!173 = distinct !DILexicalBlock(scope: !167, file: !3, line: 122, column: 5)
!174 = !DILocation(line: 123, column: 29, scope: !171)
!175 = !DILocation(line: 123, column: 35, scope: !171)
!176 = !DILocation(line: 124, column: 18, scope: !177)
!177 = distinct !DILexicalBlock(scope: !171, file: !3, line: 123, column: 40)
!178 = !DILocation(line: 124, column: 13, scope: !177)
!179 = !DILocation(line: 124, column: 24, scope: !177)
!180 = !DILocation(line: 125, column: 9, scope: !177)
!181 = !DILocation(line: 122, column: 38, scope: !173)
!182 = !DILocation(line: 122, column: 23, scope: !173)
!183 = distinct !{!183, !169, !184, !154}
!184 = !DILocation(line: 126, column: 5, scope: !167)
!185 = !DILocation(line: 127, column: 16, scope: !156)
!186 = !DILocation(line: 127, column: 5, scope: !156)
!187 = !DILocation(line: 128, column: 5, scope: !156)
!188 = distinct !DISubprogram(name: "report", scope: !3, file: !3, line: 170, type: !189, scopeLine: 170, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!189 = !DISubroutineType(types: !190)
!190 = !{null, !191, !6, !6}
!191 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !192, size: 64)
!192 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !40)
!193 = !DILocalVariable(name: "entries", arg: 1, scope: !188, file: !3, line: 170, type: !191)
!194 = !DILocation(line: 0, scope: !188)
!195 = !DILocalVariable(name: "n", arg: 2, scope: !188, file: !3, line: 170, type: !6)
!196 = !DILocalVariable(name: "total", arg: 3, scope: !188, file: !3, line: 170, type: !6)
!197 = !DILocalVariable(name: "shown", scope: !188, file: !3, line: 171, type: !6)
!198 = !DILocation(line: 172, column: 5, scope: !188)
!199 = !DILocalVariable(name: "i", scope: !200, file: !3, line: 173, type: !6)
!200 = distinct !DILexicalBlock(scope: !188, file: !3, line: 173, column: 5)
!201 = !DILocation(line: 0, scope: !200)
!202 = !DILocation(line: 173, column: 23, scope: !203)
!203 = distinct !DILexicalBlock(scope: !200, file: !3, line: 173, column: 5)
!204 = !DILocation(line: 173, column: 5, scope: !200)
!205 = !DILocation(line: 171, column: 17, scope: !188)
!206 = !DILocation(line: 174, column: 30, scope: !207)
!207 = distinct !DILexicalBlock(scope: !203, file: !3, line: 173, column: 37)
!208 = !DILocation(line: 174, column: 58, scope: !207)
!209 = !DILocation(line: 174, column: 9, scope: !207)
!210 = !DILocation(line: 175, column: 30, scope: !207)
!211 = !DILocation(line: 175, column: 48, scope: !207)
!212 = !DILocation(line: 175, column: 9, scope: !207)
!213 = !DILocation(line: 173, column: 33, scope: !203)
!214 = distinct !{!214, !204, !215, !154}
!215 = !DILocation(line: 176, column: 5, scope: !200)
!216 = !DILocation(line: 177, column: 32, scope: !188)
!217 = !DILocalVariable(name: "word", scope: !188, file: !3, line: 177, type: !191)
!218 = !DILocation(line: 178, column: 14, scope: !219)
!219 = distinct !DILexicalBlock(scope: !188, file: !3, line: 178, column: 9)
!220 = !DILocation(line: 179, column: 9, scope: !221)
!221 = distinct !DILexicalBlock(scope: !219, file: !3, line: 178, column: 23)
!222 = !DILocation(line: 180, column: 5, scope: !221)
!223 = !DILocation(line: 181, column: 43, scope: !188)
!224 = !DILocation(line: 181, column: 5, scope: !188)
!225 = !DILocation(line: 182, column: 37, scope: !188)
!226 = !DILocation(line: 182, column: 5, scope: !188)
!227 = !DILocation(line: 183, column: 1, scope: !188)
!228 = distinct !DISubprogram(name: "table_lookup", scope: !3, file: !3, line: 64, type: !229, scopeLine: 64, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!229 = !DISubroutineType(types: !230)
!230 = !{!6, !159, !74}
!231 = !DILocalVariable(name: "table", arg: 1, scope: !228, file: !3, line: 64, type: !159)
!232 = !DILocation(line: 0, scope: !228)
!233 = !DILocalVariable(name: "word", arg: 2, scope: !228, file: !3, line: 64, type: !74)
!234 = !DILocation(line: 65, column: 26, scope: !228)
!235 = !DILocalVariable(name: "index", scope: !228, file: !3, line: 65, type: !12)
!236 = !DILocalVariable(name: "probe", scope: !237, file: !3, line: 66, type: !6)
!237 = distinct !DILexicalBlock(scope: !228, file: !3, line: 66, column: 5)
!238 = !DILocation(line: 0, scope: !237)
!239 = !DILocation(line: 66, column: 5, scope: !237)
!240 = !DILocation(line: 67, column: 37, scope: !241)
!241 = distinct !DILexicalBlock(scope: !242, file: !3, line: 66, column: 54)
!242 = distinct !DILexicalBlock(scope: !237, file: !3, line: 66, column: 5)
!243 = !DILocalVariable(name: "slot", scope: !241, file: !3, line: 67, type: !191)
!244 = !DILocation(line: 0, scope: !241)
!245 = !DILocation(line: 68, column: 19, scope: !246)
!246 = distinct !DILexicalBlock(scope: !241, file: !3, line: 68, column: 13)
!247 = !DILocation(line: 68, column: 25, scope: !246)
!248 = !DILocation(line: 71, column: 13, scope: !249)
!249 = distinct !DILexicalBlock(scope: !241, file: !3, line: 71, column: 13)
!250 = !DILocation(line: 71, column: 38, scope: !249)
!251 = !DILocation(line: 74, column: 24, scope: !241)
!252 = !DILocation(line: 66, column: 50, scope: !242)
!253 = !DILocation(line: 66, column: 31, scope: !242)
!254 = distinct !{!254, !239, !255, !154}
!255 = !DILocation(line: 75, column: 5, scope: !237)
!256 = !DILocation(line: 77, column: 1, scope: !228)
!257 = distinct !DISubprogram(name: "next_word", scope: !3, file: !3, line: 80, type: !258, scopeLine: 80, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!258 = !DISubroutineType(types: !259)
!259 = !{!6, !260, !261}
!260 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !74, size: 64)
!261 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !29, size: 64)
!262 = !DILocalVariable(name: "text", arg: 1, scope: !257, file: !3, line: 80, type: !260)
!263 = !DILocation(line: 0, scope: !257)
!264 = !DILocalVariable(name: "word", arg: 2, scope: !257, file: !3, line: 80, type: !261)
!265 = !DILocation(line: 81, column: 21, scope: !257)
!266 = !DILocalVariable(name: "p", scope: !257, file: !3, line: 81, type: !74)
!267 = !DILocation(line: 82, column: 12, scope: !257)
!268 = !DILocation(line: 82, column: 15, scope: !257)
!269 = !DILocation(line: 82, column: 23, scope: !257)
!270 = !DILocation(line: 82, column: 27, scope: !257)
!271 = !DILocation(line: 82, column: 26, scope: !257)
!272 = !DILocation(line: 82, column: 5, scope: !257)
!273 = !DILocation(line: 83, column: 10, scope: !274)
!274 = distinct !DILexicalBlock(scope: !257, file: !3, line: 82, column: 55)
!275 = distinct !{!275, !272, !276, !154}
!276 = !DILocation(line: 84, column: 5, scope: !257)
!277 = !DILocalVariable(name: "length", scope: !257, file: !3, line: 85, type: !6)
!278 = !DILocation(line: 86, column: 12, scope: !257)
!279 = !DILocation(line: 86, column: 5, scope: !257)
!280 = !DILocation(line: 87, column: 20, scope: !281)
!281 = distinct !DILexicalBlock(scope: !282, file: !3, line: 87, column: 13)
!282 = distinct !DILexicalBlock(scope: !257, file: !3, line: 86, column: 40)
!283 = !DILocation(line: 88, column: 44, scope: !284)
!284 = distinct !DILexicalBlock(scope: !281, file: !3, line: 87, column: 36)
!285 = !DILocation(line: 88, column: 36, scope: !284)
!286 = !DILocation(line: 88, column: 30, scope: !284)
!287 = !DILocation(line: 88, column: 24, scope: !284)
!288 = !DILocation(line: 88, column: 13, scope: !284)
!289 = !DILocation(line: 88, column: 28, scope: !284)
!290 = !DILocation(line: 89, column: 9, scope: !284)
!291 = !DILocation(line: 90, column: 10, scope: !282)
!292 = !DILocation(line: 86, column: 35, scope: !257)
!293 = distinct !{!293, !279, !294, !154}
!294 = !DILocation(line: 91, column: 5, scope: !257)
!295 = !DILocation(line: 92, column: 5, scope: !257)
!296 = !DILocation(line: 92, column: 18, scope: !257)
!297 = !DILocation(line: 93, column: 11, scope: !257)
!298 = !DILocation(line: 94, column: 5, scope: !257)
!299 = distinct !DISubprogram(name: "table_add", scope: !3, file: !3, line: 44, type: !300, scopeLine: 44, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!300 = !DISubroutineType(types: !301)
!301 = !{!6, !126, !74, !6}
!302 = !DILocalVariable(name: "table", arg: 1, scope: !299, file: !3, line: 44, type: !126)
!303 = !DILocation(line: 0, scope: !299)
!304 = !DILocalVariable(name: "word", arg: 2, scope: !299, file: !3, line: 44, type: !74)
!305 = !DILocalVariable(name: "position", arg: 3, scope: !299, file: !3, line: 44, type: !6)
!306 = !DILocation(line: 45, column: 26, scope: !299)
!307 = !DILocalVariable(name: "index", scope: !299, file: !3, line: 45, type: !12)
!308 = !DILocalVariable(name: "probe", scope: !309, file: !3, line: 46, type: !6)
!309 = distinct !DILexicalBlock(scope: !299, file: !3, line: 46, column: 5)
!310 = !DILocation(line: 0, scope: !309)
!311 = !DILocation(line: 46, column: 5, scope: !309)
!312 = !DILocation(line: 47, column: 31, scope: !313)
!313 = distinct !DILexicalBlock(scope: !314, file: !3, line: 46, column: 54)
!314 = distinct !DILexicalBlock(scope: !309, file: !3, line: 46, column: 5)
!315 = !DILocalVariable(name: "slot", scope: !313, file: !3, line: 47, type: !161)
!316 = !DILocation(line: 0, scope: !313)
!317 = !DILocation(line: 48, column: 19, scope: !318)
!318 = distinct !DILexicalBlock(scope: !313, file: !3, line: 48, column: 13)
!319 = !DILocation(line: 48, column: 25, scope: !318)
!320 = !DILocation(line: 49, column: 13, scope: !321)
!321 = distinct !DILexicalBlock(scope: !318, file: !3, line: 48, column: 31)
!322 = !DILocation(line: 50, column: 25, scope: !321)
!323 = !DILocation(line: 51, column: 19, scope: !321)
!324 = !DILocation(line: 51, column: 30, scope: !321)
!325 = !DILocation(line: 52, column: 20, scope: !321)
!326 = !DILocation(line: 52, column: 24, scope: !321)
!327 = !DILocation(line: 53, column: 13, scope: !321)
!328 = !DILocation(line: 55, column: 13, scope: !329)
!329 = distinct !DILexicalBlock(scope: !313, file: !3, line: 55, column: 13)
!330 = !DILocation(line: 55, column: 38, scope: !329)
!331 = !DILocation(line: 56, column: 24, scope: !332)
!332 = distinct !DILexicalBlock(scope: !329, file: !3, line: 55, column: 44)
!333 = !DILocation(line: 57, column: 13, scope: !332)
!334 = !DILocation(line: 59, column: 24, scope: !313)
!335 = !DILocation(line: 46, column: 50, scope: !314)
!336 = !DILocation(line: 46, column: 31, scope: !314)
!337 = distinct !{!337, !311, !338, !154}
!338 = !DILocation(line: 60, column: 5, scope: !309)
!339 = !DILocation(line: 62, column: 1, scope: !299)
!340 = distinct !DISubprogram(name: "hash_word", scope: !3, file: !3, line: 30, type: !341, scopeLine: 30, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!341 = !DISubroutineType(types: !342)
!342 = !{!12, !74}
!343 = !DILocalVariable(name: "word", arg: 1, scope: !340, file: !3, line: 30, type: !74)
!344 = !DILocation(line: 0, scope: !340)
!345 = !DILocalVariable(name: "hash", scope: !340, file: !3, line: 31, type: !12)
!346 = !DILocalVariable(name: "p", scope: !347, file: !3, line: 32, type: !74)
!347 = distinct !DILexicalBlock(scope: !340, file: !3, line: 32, column: 5)
!348 = !DILocation(line: 0, scope: !347)
!349 = !DILocation(line: 32, column: 32, scope: !350)
!350 = distinct !DILexicalBlock(scope: !347, file: !3, line: 32, column: 5)
!351 = !DILocation(line: 32, column: 35, scope: !350)
!352 = !DILocation(line: 32, column: 5, scope: !347)
!353 = !DILocation(line: 33, column: 17, scope: !354)
!354 = distinct !DILexicalBlock(scope: !350, file: !3, line: 32, column: 49)
!355 = !DILocation(line: 33, column: 14, scope: !354)
!356 = !DILocation(line: 34, column: 14, scope: !354)
!357 = !DILocation(line: 32, column: 45, scope: !350)
!358 = distinct !{!358, !352, !359, !154}
!359 = !DILocation(line: 35, column: 5, scope: !347)
!360 = !DILocation(line: 36, column: 5, scope: !340)
!361 = distinct !DISubprogram(name: "by_count", scope: !3, file: !3, line: 111, type: !362, scopeLine: 111, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!362 = !DISubroutineType(types: !363)
!363 = !{!6, !364, !364}
!364 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !365, size: 64)
!365 = !DIDerivedType(tag: DW_TAG_const_type, baseType: null)
!366 = !DILocalVariable(name: "a", arg: 1, scope: !361, file: !3, line: 111, type: !364)
!367 = !DILocation(line: 0, scope: !361)
!368 = !DILocalVariable(name: "b", arg: 2, scope: !361, file: !3, line: 111, type: !364)
!369 = !DILocalVariable(name: "x", scope: !361, file: !3, line: 112, type: !191)
!370 = !DILocalVariable(name: "y", scope: !361, file: !3, line: 113, type: !191)
!371 = !DILocation(line: 114, column: 12, scope: !372)
!372 = distinct !DILexicalBlock(scope: !361, file: !3, line: 114, column: 9)
!373 = !DILocation(line: 114, column: 24, scope: !372)
!374 = !DILocation(line: 114, column: 18, scope: !372)
!375 = !DILocation(line: 115, column: 25, scope: !376)
!376 = distinct !DILexicalBlock(scope: !372, file: !3, line: 114, column: 31)
!377 = !DILocation(line: 115, column: 9, scope: !376)
!378 = !DILocation(line: 117, column: 15, scope: !361)
!379 = !DILocation(line: 117, column: 31, scope: !361)
!380 = !DILocation(line: 117, column: 26, scope: !361)
!381 = !DILocation(line: 117, column: 5, scope: !361)
!382 = !DILocation(line: 118, column: 1, scope: !361)
!383 = distinct !DISubprogram(name: "print_bar", scope: !3, file: !3, line: 162, type: !384, scopeLine: 162, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!384 = !DISubroutineType(types: !385)
!385 = !{null, !6, !6}
!386 = !DILocalVariable(name: "count", arg: 1, scope: !383, file: !3, line: 162, type: !6)
!387 = !DILocation(line: 0, scope: !383)
!388 = !DILocalVariable(name: "widest", arg: 2, scope: !383, file: !3, line: 162, type: !6)
!389 = !DILocation(line: 163, column: 24, scope: !383)
!390 = !DILocation(line: 163, column: 17, scope: !383)
!391 = !DILocation(line: 163, column: 36, scope: !383)
!392 = !DILocation(line: 163, column: 41, scope: !383)
!393 = !DILocalVariable(name: "width", scope: !383, file: !3, line: 163, type: !6)
!394 = !DILocalVariable(name: "i", scope: !395, file: !3, line: 164, type: !6)
!395 = distinct !DILexicalBlock(scope: !383, file: !3, line: 164, column: 5)
!396 = !DILocation(line: 0, scope: !395)
!397 = !DILocation(line: 164, column: 23, scope: !398)
!398 = distinct !DILexicalBlock(scope: !395, file: !3, line: 164, column: 5)
!399 = !DILocation(line: 164, column: 5, scope: !395)
!400 = !DILocation(line: 165, column: 9, scope: !401)
!401 = distinct !DILexicalBlock(scope: !398, file: !3, line: 164, column: 37)
!402 = !DILocation(line: 164, column: 33, scope: !398)
!403 = distinct !{!403, !399, !404, !154}
!404 = !DILocation(line: 166, column: 5, scope: !395)
!405 = !DILocation(line: 167, column: 5, scope: !383)
!406 = !DILocation(line: 168, column: 1, scope: !383)
!407 = distinct !DISubprogram(name: "longest", scope: !3, file: !3, line: 141, type: !408, scopeLine: 141, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!408 = !DISubroutineType(types: !409)
!409 = !{!191, !191, !6}
!410 = !DILocalVariable(name: "entries", arg: 1, scope: !407, file: !3, line: 141, type: !191)
!411 = !DILocation(line: 0, scope: !407)
!412 = !DILocalVariable(name: "n", arg: 2, scope: !407, file: !3, line: 141, type: !6)
!413 = !DILocalVariable(name: "best", scope: !407, file: !3, line: 142, type: !191)
!414 = !DILocalVariable(name: "best_length", scope: !407, file: !3, line: 143, type: !30)
!415 = !DILocalVariable(name: "i", scope: !416, file: !3, line: 144, type: !6)
!416 = distinct !DILexicalBlock(scope: !407, file: !3, line: 144, column: 5)
!417 = !DILocation(line: 0, scope: !416)
!418 = !DILocation(line: 144, column: 23, scope: !419)
!419 = distinct !DILexicalBlock(scope: !416, file: !3, line: 144, column: 5)
!420 = !DILocation(line: 144, column: 5, scope: !416)
!421 = !DILocation(line: 145, column: 32, scope: !422)
!422 = distinct !DILexicalBlock(scope: !419, file: !3, line: 144, column: 33)
!423 = !DILocation(line: 145, column: 25, scope: !422)
!424 = !DILocalVariable(name: "length", scope: !422, file: !3, line: 145, type: !30)
!425 = !DILocation(line: 0, scope: !422)
!426 = !DILocation(line: 146, column: 20, scope: !427)
!427 = distinct !DILexicalBlock(scope: !422, file: !3, line: 146, column: 13)
!428 = !DILocation(line: 144, column: 29, scope: !419)
!429 = distinct !{!429, !420, !430, !154}
!430 = !DILocation(line: 150, column: 5, scope: !416)
!431 = !DILocation(line: 151, column: 5, scope: !407)
!432 = distinct !DISubprogram(name: "mean_length", scope: !3, file: !3, line: 131, type: !433, scopeLine: 131, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!433 = !DISubroutineType(types: !434)
!434 = !{!35, !191, !6}
!435 = !DILocalVariable(name: "entries", arg: 1, scope: !432, file: !3, line: 131, type: !191)
!436 = !DILocation(line: 0, scope: !432)
!437 = !DILocalVariable(name: "n", arg: 2, scope: !432, file: !3, line: 131, type: !6)
!438 = !DILocalVariable(name: "letters", scope: !432, file: !3, line: 132, type: !34)
!439 = !DILocalVariable(name: "words", scope: !432, file: !3, line: 133, type: !34)
!440 = !DILocalVariable(name: "i", scope: !441, file: !3, line: 134, type: !6)
!441 = distinct !DILexicalBlock(scope: !432, file: !3, line: 134, column: 5)
!442 = !DILocation(line: 0, scope: !441)
!443 = !DILocation(line: 134, column: 23, scope: !444)
!444 = distinct !DILexicalBlock(scope: !441, file: !3, line: 134, column: 5)
!445 = !DILocation(line: 134, column: 5, scope: !441)
!446 = !DILocation(line: 136, column: 18, scope: !447)
!447 = distinct !DILexicalBlock(scope: !444, file: !3, line: 134, column: 33)
!448 = !DILocation(line: 136, column: 29, scope: !447)
!449 = !DILocation(line: 136, column: 15, scope: !447)
!450 = !DILocation(line: 135, column: 26, scope: !447)
!451 = !DILocation(line: 135, column: 50, scope: !447)
!452 = !DILocation(line: 135, column: 17, scope: !447)
!453 = !DILocation(line: 134, column: 29, scope: !444)
!454 = distinct !{!454, !445, !455, !154}
!455 = !DILocation(line: 137, column: 5, scope: !441)
!456 = !DILocation(line: 138, column: 12, scope: !432)
!457 = !DILocation(line: 138, column: 18, scope: !432)
!458 = !DILocation(line: 138, column: 5, scope: !432)
!459 = distinct !DISubprogram(name: "singletons", scope: !3, file: !3, line: 154, type: !460, scopeLine: 154, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!460 = !DISubroutineType(types: !461)
!461 = !{!6, !191, !6}
!462 = !DILocalVariable(name: "entries", arg: 1, scope: !459, file: !3, line: 154, type: !191)
!463 = !DILocation(line: 0, scope: !459)
!464 = !DILocalVariable(name: "n", arg: 2, scope: !459, file: !3, line: 154, type: !6)
!465 = !DILocalVariable(name: "count", scope: !459, file: !3, line: 155, type: !6)
!466 = !DILocalVariable(name: "i", scope: !467, file: !3, line: 156, type: !6)
!467 = distinct !DILexicalBlock(scope: !459, file: !3, line: 156, column: 5)
!468 = !DILocation(line: 0, scope: !467)
!469 = !DILocation(line: 156, column: 27, scope: !470)
!470 = distinct !DILexicalBlock(scope: !467, file: !3, line: 156, column: 5)
!471 = !DILocation(line: 156, column: 32, scope: !470)
!472 = !DILocation(line: 156, scope: !467)
!473 = !DILocation(line: 156, column: 35, scope: !470)
!474 = !DILocation(line: 156, column: 46, scope: !470)
!475 = !DILocation(line: 156, column: 52, scope: !470)
!476 = !DILocation(line: 156, column: 5, scope: !467)
!477 = !DILocation(line: 157, column: 14, scope: !478)
!478 = distinct !DILexicalBlock(scope: !470, file: !3, line: 156, column: 63)
!479 = distinct !{!479, !476, !480, !154}
!480 = !DILocation(line: 158, column: 5, scope: !467)
!481 = !DILocation(line: 159, column: 5, scope: !459)
