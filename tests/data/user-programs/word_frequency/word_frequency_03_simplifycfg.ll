; ModuleID = '/workspace/out/word_frequency_02_instcombine.ll'
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
  %call4 = call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.2, i32 noundef %call2, i32 noundef %call3) #7, !dbg !120
  %cmp = icmp sgt i32 %call2, 0, !dbg !121
  %cmp5 = icmp ne i32 %call3, 0, !dbg !122
  %1 = zext i1 %cmp5 to i32, !dbg !122
  %not. = select i1 %cmp, i32 %1, i32 1, !dbg !122
  ret i32 %not., !dbg !123
}

; Function Attrs: noinline nounwind uwtable
define internal void @table_init(ptr noundef %table) #0 !dbg !124 {
entry:
    #dbg_value(ptr %table, !128, !DIExpression(), !129)
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 4 dereferenceable(8196) %table, i8 0, i64 8196, i1 false), !dbg !130
  ret void, !dbg !131
}

; Function Attrs: noinline nounwind uwtable
define internal i32 @count_words(ptr noundef %table, ptr noundef %text) #0 !dbg !132 {
entry:
  %text.addr = alloca ptr, align 8
  %word = alloca [24 x i8], align 16
    #dbg_value(ptr %table, !135, !DIExpression(), !136)
    #dbg_value(ptr %text, !137, !DIExpression(), !136)
  store ptr %text, ptr %text.addr, align 8
    #dbg_declare(ptr %word, !138, !DIExpression(), !139)
    #dbg_value(i32 0, !140, !DIExpression(), !136)
  br label %while.cond, !dbg !141

while.cond:                                       ; preds = %if.end, %entry
  %position.0 = phi i32 [ 0, %entry ], [ %inc, %if.end ], !dbg !136
    #dbg_value(i32 %position.0, !140, !DIExpression(), !136)
    #dbg_value(ptr %text.addr, !137, !DIExpression(DW_OP_deref), !136)
  %call = call i32 @next_word(ptr noundef nonnull %text.addr, ptr noundef nonnull %word), !dbg !142
  %cmp = icmp sgt i32 %call, 0, !dbg !143
  br i1 %cmp, label %while.body, label %while.end, !dbg !141

while.body:                                       ; preds = %while.cond
  %call2 = call i32 @table_add(ptr noundef %table, ptr noundef nonnull %word, i32 noundef %position.0), !dbg !144
  %cmp3 = icmp slt i32 %call2, 0, !dbg !147
  br i1 %cmp3, label %if.then, label %if.end, !dbg !147

if.then:                                          ; preds = %while.body
  %0 = load ptr, ptr @stderr, align 8, !dbg !148
  %call4 = call i32 (ptr, ptr, ...) @fprintf(ptr noundef %0, ptr noundef nonnull @.str.3, i32 noundef %position.0) #8, !dbg !150
  br label %while.end, !dbg !151

if.end:                                           ; preds = %while.body
  %inc = add nuw nsw i32 %position.0, 1, !dbg !152
    #dbg_value(i32 %inc, !140, !DIExpression(), !136)
  br label %while.cond, !dbg !141, !llvm.loop !153

while.end:                                        ; preds = %if.then, %while.cond
  ret i32 %position.0, !dbg !156
}

; Function Attrs: noinline nounwind uwtable
define internal i32 @collect(ptr noundef %table, ptr noundef %out) #0 !dbg !157 {
entry:
    #dbg_value(ptr %table, !163, !DIExpression(), !164)
    #dbg_value(ptr %out, !165, !DIExpression(), !164)
    #dbg_value(i32 0, !166, !DIExpression(), !164)
    #dbg_value(i32 0, !167, !DIExpression(), !169)
  br label %for.cond, !dbg !170

for.cond:                                         ; preds = %for.inc, %entry
  %n.0 = phi i32 [ 0, %entry ], [ %n.1, %for.inc ], !dbg !164
  %i.0 = phi i32 [ 0, %entry ], [ %inc7, %for.inc ], !dbg !171
    #dbg_value(i32 %i.0, !167, !DIExpression(), !169)
    #dbg_value(i32 %n.0, !166, !DIExpression(), !164)
  %cmp = icmp samesign ult i32 %i.0, 256, !dbg !172
  br i1 %cmp, label %for.body, label %for.end, !dbg !174

for.body:                                         ; preds = %for.cond
  %idxprom = zext nneg i32 %i.0 to i64, !dbg !175
  %arrayidx = getelementptr inbounds nuw %struct.entry, ptr %table, i64 %idxprom, !dbg !175
  %count = getelementptr inbounds nuw i8, ptr %arrayidx, i64 24, !dbg !178
  %0 = load i32, ptr %count, align 4, !dbg !178
  %cmp1 = icmp sgt i32 %0, 0, !dbg !179
  br i1 %cmp1, label %if.then, label %for.inc, !dbg !179

if.then:                                          ; preds = %for.body
  %inc = add nsw i32 %n.0, 1, !dbg !180
    #dbg_value(i32 %inc, !166, !DIExpression(), !164)
  %idxprom2 = sext i32 %n.0 to i64, !dbg !182
  %arrayidx3 = getelementptr inbounds %struct.entry, ptr %out, i64 %idxprom2, !dbg !182
  %idxprom5 = zext nneg i32 %i.0 to i64, !dbg !183
  %arrayidx6 = getelementptr inbounds nuw %struct.entry, ptr %table, i64 %idxprom5, !dbg !183
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 4 dereferenceable(32) %arrayidx3, ptr noundef nonnull align 4 dereferenceable(32) %arrayidx6, i64 32, i1 false), !dbg !183
  br label %for.inc, !dbg !184

for.inc:                                          ; preds = %for.body, %if.then
  %n.1 = phi i32 [ %inc, %if.then ], [ %n.0, %for.body ], !dbg !164
    #dbg_value(i32 %n.1, !166, !DIExpression(), !164)
  %inc7 = add nuw nsw i32 %i.0, 1, !dbg !185
    #dbg_value(i32 %inc7, !167, !DIExpression(), !169)
  br label %for.cond, !dbg !186, !llvm.loop !187

for.end:                                          ; preds = %for.cond
  %conv = sext i32 %n.0 to i64, !dbg !189
  call void @qsort(ptr noundef %out, i64 noundef %conv, i64 noundef 32, ptr noundef nonnull @by_count) #7, !dbg !190
  ret i32 %n.0, !dbg !191
}

; Function Attrs: noinline nounwind uwtable
define internal void @report(ptr noundef %entries, i32 noundef %n, i32 noundef %total) #0 !dbg !192 {
entry:
    #dbg_value(ptr %entries, !197, !DIExpression(), !198)
    #dbg_value(i32 %n, !199, !DIExpression(), !198)
    #dbg_value(i32 %total, !200, !DIExpression(), !198)
  %cmp = icmp slt i32 %n, 8, !dbg !201
  %n. = select i1 %cmp, i32 %n, i32 8, !dbg !202
    #dbg_value(i32 %n., !203, !DIExpression(), !198)
  %call = call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.5, i32 noundef %total, i32 noundef %n) #7, !dbg !204
    #dbg_value(i32 0, !205, !DIExpression(), !207)
  br label %for.cond, !dbg !208

for.cond:                                         ; preds = %for.body, %entry
  %i.0 = phi i32 [ 0, %entry ], [ %inc, %for.body ], !dbg !209
    #dbg_value(i32 %i.0, !205, !DIExpression(), !207)
  %cmp1 = icmp slt i32 %i.0, %n., !dbg !210
  br i1 %cmp1, label %for.body, label %for.end, !dbg !212

for.body:                                         ; preds = %for.cond
  %idxprom = zext nneg i32 %i.0 to i64, !dbg !213
  %arrayidx = getelementptr inbounds nuw %struct.entry, ptr %entries, i64 %idxprom, !dbg !213
  %idxprom2 = zext nneg i32 %i.0 to i64, !dbg !215
  %arrayidx3 = getelementptr inbounds nuw %struct.entry, ptr %entries, i64 %idxprom2, !dbg !215
  %count = getelementptr inbounds nuw i8, ptr %arrayidx3, i64 24, !dbg !216
  %0 = load i32, ptr %count, align 4, !dbg !216
  %call4 = call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.6, ptr noundef %arrayidx, i32 noundef %0) #7, !dbg !217
  %idxprom5 = zext nneg i32 %i.0 to i64, !dbg !218
  %arrayidx6 = getelementptr inbounds nuw %struct.entry, ptr %entries, i64 %idxprom5, !dbg !218
  %count7 = getelementptr inbounds nuw i8, ptr %arrayidx6, i64 24, !dbg !219
  %1 = load i32, ptr %count7, align 4, !dbg !219
  %count9 = getelementptr inbounds nuw i8, ptr %entries, i64 24, !dbg !220
  %2 = load i32, ptr %count9, align 4, !dbg !220
  call void @print_bar(i32 noundef %1, i32 noundef %2), !dbg !221
  %inc = add nuw nsw i32 %i.0, 1, !dbg !222
    #dbg_value(i32 %inc, !205, !DIExpression(), !207)
  br label %for.cond, !dbg !223, !llvm.loop !224

for.end:                                          ; preds = %for.cond
  %call11 = call ptr @longest(ptr noundef %entries, i32 noundef %n), !dbg !226
    #dbg_value(ptr %call11, !227, !DIExpression(), !198)
  %cmp12.not = icmp eq ptr %call11, null, !dbg !228
  br i1 %cmp12.not, label %if.end, label %if.then, !dbg !228

if.then:                                          ; preds = %for.end
  %call15 = call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.7, ptr noundef nonnull %call11) #7, !dbg !230
  br label %if.end, !dbg !232

if.end:                                           ; preds = %if.then, %for.end
  %call16 = call double @mean_length(ptr noundef %entries, i32 noundef %n), !dbg !233
  %call17 = call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.8, double noundef %call16) #7, !dbg !234
  %call18 = call i32 @singletons(ptr noundef %entries, i32 noundef %n), !dbg !235
  %call19 = call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.9, i32 noundef %call18) #7, !dbg !236
  ret void, !dbg !237
}

; Function Attrs: noinline nounwind uwtable
define internal i32 @table_lookup(ptr noundef %table, ptr noundef %word) #0 !dbg !238 {
entry:
    #dbg_value(ptr %table, !241, !DIExpression(), !242)
    #dbg_value(ptr %word, !243, !DIExpression(), !242)
  %call = call i32 @hash_word(ptr noundef %word), !dbg !244
    #dbg_value(i32 %call, !245, !DIExpression(DW_OP_constu, 255, DW_OP_and, DW_OP_stack_value), !242)
    #dbg_value(i32 0, !246, !DIExpression(), !248)
  br label %for.cond, !dbg !249

for.cond:                                         ; preds = %for.inc, %entry
  %index.0.in = phi i32 [ %call, %entry ], [ %add, %for.inc ]
  %probe.0 = phi i32 [ 0, %entry ], [ %inc, %for.inc ], !dbg !250
  %index.0 = and i32 %index.0.in, 255, !dbg !242
    #dbg_value(i32 %probe.0, !246, !DIExpression(), !248)
    #dbg_value(i32 %index.0, !245, !DIExpression(), !242)
  %cmp = icmp samesign ult i32 %probe.0, 256, !dbg !251
  br i1 %cmp, label %for.body, label %return, !dbg !253

for.body:                                         ; preds = %for.cond
  %idxprom = zext nneg i32 %index.0 to i64, !dbg !254
  %arrayidx = getelementptr inbounds nuw %struct.entry, ptr %table, i64 %idxprom, !dbg !254
    #dbg_value(ptr %arrayidx, !256, !DIExpression(), !257)
  %count = getelementptr inbounds nuw i8, ptr %arrayidx, i64 24, !dbg !258
  %0 = load i32, ptr %count, align 4, !dbg !258
  %cmp1 = icmp eq i32 %0, 0, !dbg !260
  br i1 %cmp1, label %return, label %if.end, !dbg !260

if.end:                                           ; preds = %for.body
  %call3 = call i32 @strcmp(ptr noundef nonnull dereferenceable(1) %arrayidx, ptr noundef nonnull dereferenceable(1) %word) #9, !dbg !261
  %cmp4 = icmp eq i32 %call3, 0, !dbg !263
  br i1 %cmp4, label %if.then5, label %for.inc, !dbg !263

if.then5:                                         ; preds = %if.end
  %count6 = getelementptr inbounds nuw i8, ptr %arrayidx, i64 24, !dbg !264
  %1 = load i32, ptr %count6, align 4, !dbg !264
  br label %return, !dbg !266

for.inc:                                          ; preds = %if.end
    #dbg_value(i32 poison, !245, !DIExpression(), !242)
  %add = add nuw nsw i32 %index.0, 1, !dbg !267
    #dbg_value(i32 %add, !245, !DIExpression(DW_OP_constu, 255, DW_OP_and, DW_OP_stack_value), !242)
  %inc = add nuw nsw i32 %probe.0, 1, !dbg !268
    #dbg_value(i32 %inc, !246, !DIExpression(), !248)
  br label %for.cond, !dbg !269, !llvm.loop !270

return:                                           ; preds = %for.cond, %for.body, %if.then5
  %retval.0 = phi i32 [ 0, %for.body ], [ %1, %if.then5 ], [ 0, %for.cond ], !dbg !242
  ret i32 %retval.0, !dbg !272
}

declare i32 @printf(ptr noundef, ...) #1

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr writeonly captures(none), i8, i64, i1 immarg) #2

; Function Attrs: noinline nounwind uwtable
define internal i32 @next_word(ptr noundef %text, ptr noundef %word) #0 !dbg !273 {
entry:
    #dbg_value(ptr %text, !278, !DIExpression(), !279)
    #dbg_value(ptr %word, !280, !DIExpression(), !279)
  %0 = load ptr, ptr %text, align 8, !dbg !281
    #dbg_value(ptr %0, !282, !DIExpression(), !279)
  br label %while.cond, !dbg !283

while.cond:                                       ; preds = %while.body, %entry
  %p.0 = phi ptr [ %0, %entry ], [ %incdec.ptr, %while.body ], !dbg !279
    #dbg_value(ptr %p.0, !282, !DIExpression(), !279)
  %1 = load i8, ptr %p.0, align 1, !dbg !284
  %cmp.not = icmp eq i8 %1, 0, !dbg !285
  br i1 %cmp.not, label %while.end, label %land.rhs, !dbg !286

land.rhs:                                         ; preds = %while.cond
  %call = call ptr @__ctype_b_loc() #10, !dbg !287
  %2 = load ptr, ptr %call, align 8, !dbg !287
  %3 = load i8, ptr %p.0, align 1, !dbg !288
  %idxprom = zext i8 %3 to i64, !dbg !287
  %arrayidx = getelementptr inbounds nuw i16, ptr %2, i64 %idxprom, !dbg !287
  %4 = load i16, ptr %arrayidx, align 2, !dbg !287
  %5 = and i16 %4, 1024, !dbg !287
  %tobool.not = icmp eq i16 %5, 0, !dbg !289
  br i1 %tobool.not, label %while.body, label %while.end, !dbg !283

while.body:                                       ; preds = %land.rhs
  %incdec.ptr = getelementptr inbounds nuw i8, ptr %p.0, i64 1, !dbg !290
    #dbg_value(ptr %incdec.ptr, !282, !DIExpression(), !279)
  br label %while.cond, !dbg !283, !llvm.loop !292

while.end:                                        ; preds = %while.cond, %land.rhs
    #dbg_value(i32 0, !294, !DIExpression(), !279)
  br label %while.cond4, !dbg !295

while.cond4:                                      ; preds = %if.end, %while.end
  %p.1 = phi ptr [ %p.0, %while.end ], [ %incdec.ptr20, %if.end ], !dbg !279
  %length.0 = phi i32 [ 0, %while.end ], [ %length.1, %if.end ], !dbg !279
    #dbg_value(i32 %length.0, !294, !DIExpression(), !279)
    #dbg_value(ptr %p.1, !282, !DIExpression(), !279)
  %call5 = call ptr @__ctype_b_loc() #10, !dbg !296
  %6 = load ptr, ptr %call5, align 8, !dbg !296
  %7 = load i8, ptr %p.1, align 1, !dbg !297
  %idxprom7 = zext i8 %7 to i64, !dbg !296
  %arrayidx8 = getelementptr inbounds nuw i16, ptr %6, i64 %idxprom7, !dbg !296
  %8 = load i16, ptr %arrayidx8, align 2, !dbg !296
  %9 = and i16 %8, 1024, !dbg !296
  %tobool11.not = icmp eq i16 %9, 0, !dbg !295
  br i1 %tobool11.not, label %while.end21, label %while.body12, !dbg !295

while.body12:                                     ; preds = %while.cond4
  %cmp13 = icmp slt i32 %length.0, 23, !dbg !298
  br i1 %cmp13, label %if.then, label %if.end, !dbg !298

if.then:                                          ; preds = %while.body12
  %10 = load i8, ptr %p.1, align 1, !dbg !301
  %conv15 = zext i8 %10 to i32, !dbg !303
  %call16 = call i32 @tolower(i32 noundef %conv15) #9, !dbg !304
  %conv17 = trunc i32 %call16 to i8, !dbg !305
  %inc = add nsw i32 %length.0, 1, !dbg !306
    #dbg_value(i32 %inc, !294, !DIExpression(), !279)
  %idxprom18 = sext i32 %length.0 to i64, !dbg !307
  %arrayidx19 = getelementptr inbounds i8, ptr %word, i64 %idxprom18, !dbg !307
  store i8 %conv17, ptr %arrayidx19, align 1, !dbg !308
  br label %if.end, !dbg !309

if.end:                                           ; preds = %if.then, %while.body12
  %length.1 = phi i32 [ %inc, %if.then ], [ %length.0, %while.body12 ], !dbg !279
    #dbg_value(i32 %length.1, !294, !DIExpression(), !279)
  %incdec.ptr20 = getelementptr inbounds nuw i8, ptr %p.1, i64 1, !dbg !310
    #dbg_value(ptr %incdec.ptr20, !282, !DIExpression(), !279)
  br label %while.cond4, !dbg !295, !llvm.loop !311

while.end21:                                      ; preds = %while.cond4
  %idxprom22 = sext i32 %length.0 to i64, !dbg !313
  %arrayidx23 = getelementptr inbounds i8, ptr %word, i64 %idxprom22, !dbg !313
  store i8 0, ptr %arrayidx23, align 1, !dbg !314
  store ptr %p.1, ptr %text, align 8, !dbg !315
  ret i32 %length.0, !dbg !316
}

; Function Attrs: noinline nounwind uwtable
define internal i32 @table_add(ptr noundef %table, ptr noundef %word, i32 noundef %position) #0 !dbg !317 {
entry:
    #dbg_value(ptr %table, !320, !DIExpression(), !321)
    #dbg_value(ptr %word, !322, !DIExpression(), !321)
    #dbg_value(i32 %position, !323, !DIExpression(), !321)
  %call = call i32 @hash_word(ptr noundef %word), !dbg !324
    #dbg_value(i32 %call, !325, !DIExpression(DW_OP_constu, 255, DW_OP_and, DW_OP_stack_value), !321)
    #dbg_value(i32 0, !326, !DIExpression(), !328)
  br label %for.cond, !dbg !329

for.cond:                                         ; preds = %for.inc, %entry
  %index.0.in = phi i32 [ %call, %entry ], [ %add, %for.inc ]
  %probe.0 = phi i32 [ 0, %entry ], [ %inc14, %for.inc ], !dbg !330
  %index.0 = and i32 %index.0.in, 255, !dbg !321
    #dbg_value(i32 %probe.0, !326, !DIExpression(), !328)
    #dbg_value(i32 %index.0, !325, !DIExpression(), !321)
  %cmp = icmp samesign ult i32 %probe.0, 256, !dbg !331
  br i1 %cmp, label %for.body, label %return, !dbg !333

for.body:                                         ; preds = %for.cond
  %idxprom = zext nneg i32 %index.0 to i64, !dbg !334
  %arrayidx = getelementptr inbounds nuw %struct.entry, ptr %table, i64 %idxprom, !dbg !334
    #dbg_value(ptr %arrayidx, !336, !DIExpression(), !337)
  %count = getelementptr inbounds nuw i8, ptr %arrayidx, i64 24, !dbg !338
  %0 = load i32, ptr %count, align 4, !dbg !338
  %cmp1 = icmp eq i32 %0, 0, !dbg !340
  br i1 %cmp1, label %if.then, label %if.end, !dbg !340

if.then:                                          ; preds = %for.body
  %call3 = call ptr @strncpy(ptr noundef nonnull dereferenceable(1) %arrayidx, ptr noundef nonnull dereferenceable(1) %word, i64 noundef 23) #7, !dbg !341
  %count4 = getelementptr inbounds nuw i8, ptr %arrayidx, i64 24, !dbg !343
  store i32 1, ptr %count4, align 4, !dbg !344
  %first_seen = getelementptr inbounds nuw i8, ptr %arrayidx, i64 28, !dbg !345
  store i32 %position, ptr %first_seen, align 4, !dbg !346
  %used = getelementptr inbounds nuw i8, ptr %table, i64 8192, !dbg !347
  %1 = load i32, ptr %used, align 4, !dbg !348
  %inc = add nsw i32 %1, 1, !dbg !348
  store i32 %inc, ptr %used, align 4, !dbg !348
  br label %return, !dbg !349

if.end:                                           ; preds = %for.body
  %call7 = call i32 @strcmp(ptr noundef nonnull dereferenceable(1) %arrayidx, ptr noundef nonnull dereferenceable(1) %word) #9, !dbg !350
  %cmp8 = icmp eq i32 %call7, 0, !dbg !352
  br i1 %cmp8, label %if.then9, label %for.inc, !dbg !352

if.then9:                                         ; preds = %if.end
  %count10 = getelementptr inbounds nuw i8, ptr %arrayidx, i64 24, !dbg !353
  %2 = load i32, ptr %count10, align 4, !dbg !355
  %inc11 = add nsw i32 %2, 1, !dbg !355
  store i32 %inc11, ptr %count10, align 4, !dbg !355
  br label %return, !dbg !356

for.inc:                                          ; preds = %if.end
    #dbg_value(i32 poison, !325, !DIExpression(), !321)
  %add = add nuw nsw i32 %index.0, 1, !dbg !357
    #dbg_value(i32 %add, !325, !DIExpression(DW_OP_constu, 255, DW_OP_and, DW_OP_stack_value), !321)
  %inc14 = add nuw nsw i32 %probe.0, 1, !dbg !358
    #dbg_value(i32 %inc14, !326, !DIExpression(), !328)
  br label %for.cond, !dbg !359, !llvm.loop !360

return:                                           ; preds = %for.cond, %if.then9, %if.then
  %retval.0 = phi i32 [ 1, %if.then ], [ 0, %if.then9 ], [ -1, %for.cond ], !dbg !321
  ret i32 %retval.0, !dbg !362
}

; Function Attrs: nounwind
declare i32 @fprintf(ptr noundef, ptr noundef, ...) #3

; Function Attrs: nounwind willreturn memory(none)
declare ptr @__ctype_b_loc() #4

; Function Attrs: nounwind willreturn memory(read)
declare i32 @tolower(i32 noundef) #5

; Function Attrs: noinline nounwind uwtable
define internal i32 @hash_word(ptr noundef %word) #0 !dbg !363 {
entry:
    #dbg_value(ptr %word, !366, !DIExpression(), !367)
    #dbg_value(i32 -2128831035, !368, !DIExpression(), !367)
    #dbg_value(ptr %word, !369, !DIExpression(), !371)
  br label %for.cond, !dbg !372

for.cond:                                         ; preds = %for.inc, %entry
  %hash.0 = phi i32 [ -2128831035, %entry ], [ %mul, %for.inc ], !dbg !367
  %p.0 = phi ptr [ %word, %entry ], [ %incdec.ptr, %for.inc ], !dbg !373
    #dbg_value(ptr %p.0, !369, !DIExpression(), !371)
    #dbg_value(i32 %hash.0, !368, !DIExpression(), !367)
  %0 = load i8, ptr %p.0, align 1, !dbg !374
  %cmp.not = icmp eq i8 %0, 0, !dbg !376
  br i1 %cmp.not, label %for.end, label %for.inc, !dbg !377

for.inc:                                          ; preds = %for.cond
    #dbg_value(!DIArgList(i32 poison, i8 poison), !368, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_LLVM_convert, 32, DW_ATE_unsigned, DW_OP_xor, DW_OP_stack_value), !367)
    #dbg_value(!DIArgList(i32 poison, i8 poison), !368, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_LLVM_convert, 32, DW_ATE_unsigned, DW_OP_xor, DW_OP_constu, 16777619, DW_OP_mul, DW_OP_stack_value), !367)
  %1 = load i8, ptr %p.0, align 1, !dbg !378
    #dbg_value(!DIArgList(i32 %hash.0, i8 %1), !368, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_LLVM_convert, 32, DW_ATE_unsigned, DW_OP_xor, DW_OP_constu, 16777619, DW_OP_mul, DW_OP_stack_value), !367)
  %conv2 = zext i8 %1 to i32, !dbg !380
    #dbg_value(!DIArgList(i32 %hash.0, i32 %conv2), !368, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_xor, DW_OP_constu, 16777619, DW_OP_mul, DW_OP_stack_value), !367)
  %xor = xor i32 %hash.0, %conv2, !dbg !381
    #dbg_value(i32 %xor, !368, !DIExpression(DW_OP_constu, 16777619, DW_OP_mul, DW_OP_stack_value), !367)
  %mul = mul i32 %xor, 16777619, !dbg !382
    #dbg_value(i32 %mul, !368, !DIExpression(), !367)
  %incdec.ptr = getelementptr inbounds nuw i8, ptr %p.0, i64 1, !dbg !383
    #dbg_value(ptr %incdec.ptr, !369, !DIExpression(), !371)
  br label %for.cond, !dbg !384, !llvm.loop !385

for.end:                                          ; preds = %for.cond
  ret i32 %hash.0, !dbg !387
}

; Function Attrs: nounwind
declare ptr @strncpy(ptr noundef, ptr noundef, i64 noundef) #3

; Function Attrs: nounwind willreturn memory(read)
declare i32 @strcmp(ptr noundef, ptr noundef) #5

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #6

declare void @qsort(ptr noundef, i64 noundef, i64 noundef, ptr noundef) #1

; Function Attrs: noinline nounwind uwtable
define internal i32 @by_count(ptr noundef %a, ptr noundef %b) #0 !dbg !388 {
entry:
    #dbg_value(ptr %a, !393, !DIExpression(), !394)
    #dbg_value(ptr %b, !395, !DIExpression(), !394)
    #dbg_value(ptr %a, !396, !DIExpression(), !394)
    #dbg_value(ptr %b, !397, !DIExpression(), !394)
  %count = getelementptr inbounds nuw i8, ptr %a, i64 24, !dbg !398
  %0 = load i32, ptr %count, align 4, !dbg !398
  %count1 = getelementptr inbounds nuw i8, ptr %b, i64 24, !dbg !400
  %1 = load i32, ptr %count1, align 4, !dbg !400
  %cmp.not = icmp eq i32 %0, %1, !dbg !401
  br i1 %cmp.not, label %if.end, label %if.then, !dbg !401

if.then:                                          ; preds = %entry
  %count2 = getelementptr inbounds nuw i8, ptr %b, i64 24, !dbg !402
  %2 = load i32, ptr %count2, align 4, !dbg !402
  %count3 = getelementptr inbounds nuw i8, ptr %a, i64 24, !dbg !404
  %3 = load i32, ptr %count3, align 4, !dbg !404
  %sub = sub nsw i32 %2, %3, !dbg !405
  br label %return, !dbg !406

if.end:                                           ; preds = %entry
  %first_seen = getelementptr inbounds nuw i8, ptr %a, i64 28, !dbg !407
  %4 = load i32, ptr %first_seen, align 4, !dbg !407
  %first_seen4 = getelementptr inbounds nuw i8, ptr %b, i64 28, !dbg !408
  %5 = load i32, ptr %first_seen4, align 4, !dbg !408
  %sub5 = sub nsw i32 %4, %5, !dbg !409
  br label %return, !dbg !410

return:                                           ; preds = %if.end, %if.then
  %retval.0 = phi i32 [ %sub, %if.then ], [ %sub5, %if.end ], !dbg !394
  ret i32 %retval.0, !dbg !411
}

; Function Attrs: noinline nounwind uwtable
define internal void @print_bar(i32 noundef %count, i32 noundef %widest) #0 !dbg !412 {
entry:
    #dbg_value(i32 %count, !415, !DIExpression(), !416)
    #dbg_value(i32 %widest, !417, !DIExpression(), !416)
  %cmp = icmp sgt i32 %widest, 0, !dbg !418
  br i1 %cmp, label %cond.true, label %cond.end, !dbg !419

cond.true:                                        ; preds = %entry
  %mul = mul nsw i32 %count, 30, !dbg !420
  %div = sdiv i32 %mul, %widest, !dbg !421
  br label %cond.end, !dbg !419

cond.end:                                         ; preds = %entry, %cond.true
  %cond = phi i32 [ %div, %cond.true ], [ 0, %entry ], !dbg !419
    #dbg_value(i32 %cond, !422, !DIExpression(), !416)
    #dbg_value(i32 0, !423, !DIExpression(), !425)
  br label %for.cond, !dbg !426

for.cond:                                         ; preds = %for.body, %cond.end
  %i.0 = phi i32 [ 0, %cond.end ], [ %inc, %for.body ], !dbg !427
    #dbg_value(i32 %i.0, !423, !DIExpression(), !425)
  %cmp1 = icmp slt i32 %i.0, %cond, !dbg !428
  br i1 %cmp1, label %for.body, label %for.end, !dbg !430

for.body:                                         ; preds = %for.cond
  %call = call i32 @putchar(i32 noundef 35) #7, !dbg !431
  %inc = add nuw nsw i32 %i.0, 1, !dbg !433
    #dbg_value(i32 %inc, !423, !DIExpression(), !425)
  br label %for.cond, !dbg !434, !llvm.loop !435

for.end:                                          ; preds = %for.cond
  %call2 = call i32 @putchar(i32 noundef 10) #7, !dbg !437
  ret void, !dbg !438
}

; Function Attrs: noinline nounwind uwtable
define internal ptr @longest(ptr noundef %entries, i32 noundef %n) #0 !dbg !439 {
entry:
    #dbg_value(ptr %entries, !442, !DIExpression(), !443)
    #dbg_value(i32 %n, !444, !DIExpression(), !443)
    #dbg_value(ptr null, !445, !DIExpression(), !443)
    #dbg_value(i64 0, !446, !DIExpression(), !443)
    #dbg_value(i32 0, !447, !DIExpression(), !449)
  br label %for.cond, !dbg !450

for.cond:                                         ; preds = %for.body, %entry
  %best.0 = phi ptr [ null, %entry ], [ %best.1, %for.body ], !dbg !443
  %best_length.0 = phi i64 [ 0, %entry ], [ %best_length.1, %for.body ], !dbg !443
  %i.0 = phi i32 [ 0, %entry ], [ %inc, %for.body ], !dbg !451
    #dbg_value(i32 %i.0, !447, !DIExpression(), !449)
    #dbg_value(i64 %best_length.0, !446, !DIExpression(), !443)
    #dbg_value(ptr %best.0, !445, !DIExpression(), !443)
  %cmp = icmp slt i32 %i.0, %n, !dbg !452
  br i1 %cmp, label %for.body, label %for.end, !dbg !454

for.body:                                         ; preds = %for.cond
  %idxprom = zext nneg i32 %i.0 to i64, !dbg !455
  %arrayidx = getelementptr inbounds nuw %struct.entry, ptr %entries, i64 %idxprom, !dbg !455
  %call = call i64 @strlen(ptr noundef nonnull dereferenceable(1) %arrayidx) #9, !dbg !457
    #dbg_value(i64 %call, !458, !DIExpression(), !459)
  %cmp1 = icmp ugt i64 %call, %best_length.0, !dbg !460
  %idxprom2 = zext nneg i32 %i.0 to i64, !dbg !460
  %arrayidx3 = getelementptr inbounds nuw %struct.entry, ptr %entries, i64 %idxprom2, !dbg !460
  %best.1 = select i1 %cmp1, ptr %arrayidx3, ptr %best.0, !dbg !460
  %best_length.1 = select i1 %cmp1, i64 %call, i64 %best_length.0, !dbg !460
    #dbg_value(i64 %best_length.1, !446, !DIExpression(), !443)
    #dbg_value(ptr %best.1, !445, !DIExpression(), !443)
  %inc = add nuw nsw i32 %i.0, 1, !dbg !462
    #dbg_value(i32 %inc, !447, !DIExpression(), !449)
  br label %for.cond, !dbg !463, !llvm.loop !464

for.end:                                          ; preds = %for.cond
  ret ptr %best.0, !dbg !466
}

; Function Attrs: noinline nounwind uwtable
define internal double @mean_length(ptr noundef %entries, i32 noundef %n) #0 !dbg !467 {
entry:
    #dbg_value(ptr %entries, !470, !DIExpression(), !471)
    #dbg_value(i32 %n, !472, !DIExpression(), !471)
    #dbg_value(i64 0, !473, !DIExpression(), !471)
    #dbg_value(i64 0, !474, !DIExpression(), !471)
    #dbg_value(i32 0, !475, !DIExpression(), !477)
  br label %for.cond, !dbg !478

for.cond:                                         ; preds = %for.inc, %entry
  %letters.0 = phi i64 [ 0, %entry ], [ %add, %for.inc ], !dbg !471
  %words.0 = phi i64 [ 0, %entry ], [ %add7, %for.inc ], !dbg !471
  %i.0 = phi i32 [ 0, %entry ], [ %inc, %for.inc ], !dbg !479
    #dbg_value(i32 %i.0, !475, !DIExpression(), !477)
    #dbg_value(i64 %words.0, !474, !DIExpression(), !471)
    #dbg_value(i64 %letters.0, !473, !DIExpression(), !471)
  %cmp = icmp slt i32 %i.0, %n, !dbg !480
  br i1 %cmp, label %for.inc, label %for.end, !dbg !482

for.inc:                                          ; preds = %for.cond
    #dbg_value(!DIArgList(i64 poison, i64 poison, i32 poison), !473, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_LLVM_arg, 2, DW_OP_LLVM_convert, 32, DW_ATE_signed, DW_OP_LLVM_convert, 64, DW_ATE_signed, DW_OP_mul, DW_OP_plus, DW_OP_stack_value), !471)
    #dbg_value(!DIArgList(i64 poison, i32 poison), !474, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_LLVM_convert, 32, DW_ATE_signed, DW_OP_LLVM_convert, 64, DW_ATE_signed, DW_OP_plus, DW_OP_stack_value), !471)
  %idxprom3 = zext nneg i32 %i.0 to i64, !dbg !483
  %arrayidx4 = getelementptr inbounds nuw %struct.entry, ptr %entries, i64 %idxprom3, !dbg !483
  %count5 = getelementptr inbounds nuw i8, ptr %arrayidx4, i64 24, !dbg !485
  %0 = load i32, ptr %count5, align 4, !dbg !485
    #dbg_value(!DIArgList(i64 %words.0, i32 %0), !474, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_LLVM_convert, 32, DW_ATE_signed, DW_OP_LLVM_convert, 64, DW_ATE_signed, DW_OP_plus, DW_OP_stack_value), !471)
  %conv6 = sext i32 %0 to i64, !dbg !483
    #dbg_value(!DIArgList(i64 %words.0, i64 %conv6), !474, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_plus, DW_OP_stack_value), !471)
  %add7 = add nsw i64 %words.0, %conv6, !dbg !486
    #dbg_value(i64 %add7, !474, !DIExpression(), !471)
  %idxprom = zext nneg i32 %i.0 to i64, !dbg !487
  %arrayidx = getelementptr inbounds nuw %struct.entry, ptr %entries, i64 %idxprom, !dbg !487
  %call = call i64 @strlen(ptr noundef nonnull dereferenceable(1) %arrayidx) #9, !dbg !488
  %idxprom1 = zext nneg i32 %i.0 to i64, !dbg !489
  %arrayidx2 = getelementptr inbounds nuw %struct.entry, ptr %entries, i64 %idxprom1, !dbg !489
  %count = getelementptr inbounds nuw i8, ptr %arrayidx2, i64 24, !dbg !490
  %1 = load i32, ptr %count, align 4, !dbg !490
    #dbg_value(!DIArgList(i64 %letters.0, i64 %call, i32 %1), !473, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_LLVM_arg, 2, DW_OP_LLVM_convert, 32, DW_ATE_signed, DW_OP_LLVM_convert, 64, DW_ATE_signed, DW_OP_mul, DW_OP_plus, DW_OP_stack_value), !471)
  %conv = sext i32 %1 to i64, !dbg !489
    #dbg_value(!DIArgList(i64 %letters.0, i64 %call, i64 %conv), !473, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_LLVM_arg, 2, DW_OP_mul, DW_OP_plus, DW_OP_stack_value), !471)
  %mul = mul nsw i64 %call, %conv, !dbg !491
    #dbg_value(!DIArgList(i64 %letters.0, i64 %mul), !473, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_plus, DW_OP_stack_value), !471)
  %add = add nsw i64 %letters.0, %mul, !dbg !492
    #dbg_value(i64 %add, !473, !DIExpression(), !471)
  %inc = add nuw nsw i32 %i.0, 1, !dbg !493
    #dbg_value(i32 %inc, !475, !DIExpression(), !477)
  br label %for.cond, !dbg !494, !llvm.loop !495

for.end:                                          ; preds = %for.cond
  %cmp8 = icmp sgt i64 %words.0, 0, !dbg !497
  %conv10 = sitofp i64 %letters.0 to double, !dbg !498
  %conv11 = sitofp i64 %words.0 to double, !dbg !498
  %div = fdiv double %conv10, %conv11, !dbg !498
  %cond = select i1 %cmp8, double %div, double 0.000000e+00, !dbg !498
  ret double %cond, !dbg !499
}

; Function Attrs: noinline nounwind uwtable
define internal i32 @singletons(ptr noundef %entries, i32 noundef %n) #0 !dbg !500 {
entry:
    #dbg_value(ptr %entries, !503, !DIExpression(), !504)
    #dbg_value(i32 %n, !505, !DIExpression(), !504)
    #dbg_value(i32 0, !506, !DIExpression(), !504)
    #dbg_value(i32 %n, !507, !DIExpression(DW_OP_constu, 1, DW_OP_minus, DW_OP_stack_value), !509)
  br label %for.cond, !dbg !510

for.cond:                                         ; preds = %for.inc, %entry
  %count.0 = phi i32 [ 0, %entry ], [ %inc, %for.inc ], !dbg !504
  %i.0.in = phi i32 [ %n, %entry ], [ %i.0, %for.inc ]
  %i.0 = add nsw i32 %i.0.in, -1, !dbg !511
    #dbg_value(i32 %i.0, !507, !DIExpression(), !509)
    #dbg_value(i32 %count.0, !506, !DIExpression(), !504)
  %cmp = icmp sgt i32 %i.0.in, 0, !dbg !512
  br i1 %cmp, label %land.rhs, label %for.end, !dbg !514

land.rhs:                                         ; preds = %for.cond
  %idxprom = sext i32 %i.0 to i64, !dbg !515
  %arrayidx = getelementptr inbounds %struct.entry, ptr %entries, i64 %idxprom, !dbg !515
  %count1 = getelementptr inbounds nuw i8, ptr %arrayidx, i64 24, !dbg !516
  %0 = load i32, ptr %count1, align 4, !dbg !516
  %cmp2 = icmp eq i32 %0, 1, !dbg !517
  br i1 %cmp2, label %for.inc, label %for.end, !dbg !518

for.inc:                                          ; preds = %land.rhs
    #dbg_value(i32 %count.0, !506, !DIExpression(DW_OP_plus_uconst, 1, DW_OP_stack_value), !504)
  %inc = add nuw nsw i32 %count.0, 1, !dbg !519
    #dbg_value(i32 %inc, !506, !DIExpression(), !504)
    #dbg_value(i32 %i.0, !507, !DIExpression(DW_OP_constu, 1, DW_OP_minus, DW_OP_stack_value), !509)
  br label %for.cond, !dbg !521, !llvm.loop !522

for.end:                                          ; preds = %for.cond, %land.rhs
  ret i32 %count.0, !dbg !524
}

declare i32 @putchar(i32 noundef) #1

; Function Attrs: nounwind willreturn memory(read)
declare i64 @strlen(ptr noundef) #5

attributes #0 = { noinline nounwind uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #3 = { nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind willreturn memory(none) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #5 = { nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #6 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #7 = { nounwind }
attributes #8 = { cold nounwind }
attributes #9 = { nounwind willreturn memory(read) }
attributes #10 = { nounwind willreturn memory(none) }

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
!121 = !DILocation(line: 195, column: 18, scope: !2)
!122 = !DILocation(line: 195, column: 22, scope: !2)
!123 = !DILocation(line: 195, column: 5, scope: !2)
!124 = distinct !DISubprogram(name: "table_init", scope: !3, file: !3, line: 39, type: !125, scopeLine: 39, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!125 = !DISubroutineType(types: !126)
!126 = !{null, !127}
!127 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !96, size: 64)
!128 = !DILocalVariable(name: "table", arg: 1, scope: !124, file: !3, line: 39, type: !127)
!129 = !DILocation(line: 0, scope: !124)
!130 = !DILocation(line: 40, column: 5, scope: !124)
!131 = !DILocation(line: 41, column: 1, scope: !124)
!132 = distinct !DISubprogram(name: "count_words", scope: !3, file: !3, line: 97, type: !133, scopeLine: 97, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!133 = !DISubroutineType(types: !134)
!134 = !{!6, !127, !74}
!135 = !DILocalVariable(name: "table", arg: 1, scope: !132, file: !3, line: 97, type: !127)
!136 = !DILocation(line: 0, scope: !132)
!137 = !DILocalVariable(name: "text", arg: 2, scope: !132, file: !3, line: 97, type: !74)
!138 = !DILocalVariable(name: "word", scope: !132, file: !3, line: 98, type: !43)
!139 = !DILocation(line: 98, column: 10, scope: !132)
!140 = !DILocalVariable(name: "position", scope: !132, file: !3, line: 99, type: !6)
!141 = !DILocation(line: 100, column: 5, scope: !132)
!142 = !DILocation(line: 100, column: 12, scope: !132)
!143 = !DILocation(line: 100, column: 35, scope: !132)
!144 = !DILocation(line: 101, column: 13, scope: !145)
!145 = distinct !DILexicalBlock(scope: !146, file: !3, line: 101, column: 13)
!146 = distinct !DILexicalBlock(scope: !132, file: !3, line: 100, column: 40)
!147 = !DILocation(line: 101, column: 46, scope: !145)
!148 = !DILocation(line: 102, column: 21, scope: !149)
!149 = distinct !DILexicalBlock(scope: !145, file: !3, line: 101, column: 51)
!150 = !DILocation(line: 102, column: 13, scope: !149)
!151 = !DILocation(line: 103, column: 13, scope: !149)
!152 = !DILocation(line: 105, column: 17, scope: !146)
!153 = distinct !{!153, !141, !154, !155}
!154 = !DILocation(line: 106, column: 5, scope: !132)
!155 = !{!"llvm.loop.mustprogress"}
!156 = !DILocation(line: 107, column: 5, scope: !132)
!157 = distinct !DISubprogram(name: "collect", scope: !3, file: !3, line: 120, type: !158, scopeLine: 120, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!158 = !DISubroutineType(types: !159)
!159 = !{!6, !160, !162}
!160 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !161, size: 64)
!161 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !96)
!162 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !40, size: 64)
!163 = !DILocalVariable(name: "table", arg: 1, scope: !157, file: !3, line: 120, type: !160)
!164 = !DILocation(line: 0, scope: !157)
!165 = !DILocalVariable(name: "out", arg: 2, scope: !157, file: !3, line: 120, type: !162)
!166 = !DILocalVariable(name: "n", scope: !157, file: !3, line: 121, type: !6)
!167 = !DILocalVariable(name: "i", scope: !168, file: !3, line: 122, type: !6)
!168 = distinct !DILexicalBlock(scope: !157, file: !3, line: 122, column: 5)
!169 = !DILocation(line: 0, scope: !168)
!170 = !DILocation(line: 122, column: 10, scope: !168)
!171 = !DILocation(line: 122, scope: !168)
!172 = !DILocation(line: 122, column: 23, scope: !173)
!173 = distinct !DILexicalBlock(scope: !168, file: !3, line: 122, column: 5)
!174 = !DILocation(line: 122, column: 5, scope: !168)
!175 = !DILocation(line: 123, column: 13, scope: !176)
!176 = distinct !DILexicalBlock(scope: !177, file: !3, line: 123, column: 13)
!177 = distinct !DILexicalBlock(scope: !173, file: !3, line: 122, column: 42)
!178 = !DILocation(line: 123, column: 29, scope: !176)
!179 = !DILocation(line: 123, column: 35, scope: !176)
!180 = !DILocation(line: 124, column: 18, scope: !181)
!181 = distinct !DILexicalBlock(scope: !176, file: !3, line: 123, column: 40)
!182 = !DILocation(line: 124, column: 13, scope: !181)
!183 = !DILocation(line: 124, column: 24, scope: !181)
!184 = !DILocation(line: 125, column: 9, scope: !181)
!185 = !DILocation(line: 122, column: 38, scope: !173)
!186 = !DILocation(line: 122, column: 5, scope: !173)
!187 = distinct !{!187, !174, !188, !155}
!188 = !DILocation(line: 126, column: 5, scope: !168)
!189 = !DILocation(line: 127, column: 16, scope: !157)
!190 = !DILocation(line: 127, column: 5, scope: !157)
!191 = !DILocation(line: 128, column: 5, scope: !157)
!192 = distinct !DISubprogram(name: "report", scope: !3, file: !3, line: 170, type: !193, scopeLine: 170, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!193 = !DISubroutineType(types: !194)
!194 = !{null, !195, !6, !6}
!195 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !196, size: 64)
!196 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !40)
!197 = !DILocalVariable(name: "entries", arg: 1, scope: !192, file: !3, line: 170, type: !195)
!198 = !DILocation(line: 0, scope: !192)
!199 = !DILocalVariable(name: "n", arg: 2, scope: !192, file: !3, line: 170, type: !6)
!200 = !DILocalVariable(name: "total", arg: 3, scope: !192, file: !3, line: 170, type: !6)
!201 = !DILocation(line: 171, column: 19, scope: !192)
!202 = !DILocation(line: 171, column: 17, scope: !192)
!203 = !DILocalVariable(name: "shown", scope: !192, file: !3, line: 171, type: !6)
!204 = !DILocation(line: 172, column: 5, scope: !192)
!205 = !DILocalVariable(name: "i", scope: !206, file: !3, line: 173, type: !6)
!206 = distinct !DILexicalBlock(scope: !192, file: !3, line: 173, column: 5)
!207 = !DILocation(line: 0, scope: !206)
!208 = !DILocation(line: 173, column: 10, scope: !206)
!209 = !DILocation(line: 173, scope: !206)
!210 = !DILocation(line: 173, column: 23, scope: !211)
!211 = distinct !DILexicalBlock(scope: !206, file: !3, line: 173, column: 5)
!212 = !DILocation(line: 173, column: 5, scope: !206)
!213 = !DILocation(line: 174, column: 30, scope: !214)
!214 = distinct !DILexicalBlock(scope: !211, file: !3, line: 173, column: 37)
!215 = !DILocation(line: 174, column: 47, scope: !214)
!216 = !DILocation(line: 174, column: 58, scope: !214)
!217 = !DILocation(line: 174, column: 9, scope: !214)
!218 = !DILocation(line: 175, column: 19, scope: !214)
!219 = !DILocation(line: 175, column: 30, scope: !214)
!220 = !DILocation(line: 175, column: 48, scope: !214)
!221 = !DILocation(line: 175, column: 9, scope: !214)
!222 = !DILocation(line: 173, column: 33, scope: !211)
!223 = !DILocation(line: 173, column: 5, scope: !211)
!224 = distinct !{!224, !212, !225, !155}
!225 = !DILocation(line: 176, column: 5, scope: !206)
!226 = !DILocation(line: 177, column: 32, scope: !192)
!227 = !DILocalVariable(name: "word", scope: !192, file: !3, line: 177, type: !195)
!228 = !DILocation(line: 178, column: 14, scope: !229)
!229 = distinct !DILexicalBlock(scope: !192, file: !3, line: 178, column: 9)
!230 = !DILocation(line: 179, column: 9, scope: !231)
!231 = distinct !DILexicalBlock(scope: !229, file: !3, line: 178, column: 23)
!232 = !DILocation(line: 180, column: 5, scope: !231)
!233 = !DILocation(line: 181, column: 43, scope: !192)
!234 = !DILocation(line: 181, column: 5, scope: !192)
!235 = !DILocation(line: 182, column: 37, scope: !192)
!236 = !DILocation(line: 182, column: 5, scope: !192)
!237 = !DILocation(line: 183, column: 1, scope: !192)
!238 = distinct !DISubprogram(name: "table_lookup", scope: !3, file: !3, line: 64, type: !239, scopeLine: 64, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!239 = !DISubroutineType(types: !240)
!240 = !{!6, !160, !74}
!241 = !DILocalVariable(name: "table", arg: 1, scope: !238, file: !3, line: 64, type: !160)
!242 = !DILocation(line: 0, scope: !238)
!243 = !DILocalVariable(name: "word", arg: 2, scope: !238, file: !3, line: 64, type: !74)
!244 = !DILocation(line: 65, column: 26, scope: !238)
!245 = !DILocalVariable(name: "index", scope: !238, file: !3, line: 65, type: !12)
!246 = !DILocalVariable(name: "probe", scope: !247, file: !3, line: 66, type: !6)
!247 = distinct !DILexicalBlock(scope: !238, file: !3, line: 66, column: 5)
!248 = !DILocation(line: 0, scope: !247)
!249 = !DILocation(line: 66, column: 10, scope: !247)
!250 = !DILocation(line: 66, scope: !247)
!251 = !DILocation(line: 66, column: 31, scope: !252)
!252 = distinct !DILexicalBlock(scope: !247, file: !3, line: 66, column: 5)
!253 = !DILocation(line: 66, column: 5, scope: !247)
!254 = !DILocation(line: 67, column: 37, scope: !255)
!255 = distinct !DILexicalBlock(scope: !252, file: !3, line: 66, column: 54)
!256 = !DILocalVariable(name: "slot", scope: !255, file: !3, line: 67, type: !195)
!257 = !DILocation(line: 0, scope: !255)
!258 = !DILocation(line: 68, column: 19, scope: !259)
!259 = distinct !DILexicalBlock(scope: !255, file: !3, line: 68, column: 13)
!260 = !DILocation(line: 68, column: 25, scope: !259)
!261 = !DILocation(line: 71, column: 13, scope: !262)
!262 = distinct !DILexicalBlock(scope: !255, file: !3, line: 71, column: 13)
!263 = !DILocation(line: 71, column: 38, scope: !262)
!264 = !DILocation(line: 72, column: 26, scope: !265)
!265 = distinct !DILexicalBlock(scope: !262, file: !3, line: 71, column: 44)
!266 = !DILocation(line: 72, column: 13, scope: !265)
!267 = !DILocation(line: 74, column: 24, scope: !255)
!268 = !DILocation(line: 66, column: 50, scope: !252)
!269 = !DILocation(line: 66, column: 5, scope: !252)
!270 = distinct !{!270, !253, !271, !155}
!271 = !DILocation(line: 75, column: 5, scope: !247)
!272 = !DILocation(line: 77, column: 1, scope: !238)
!273 = distinct !DISubprogram(name: "next_word", scope: !3, file: !3, line: 80, type: !274, scopeLine: 80, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!274 = !DISubroutineType(types: !275)
!275 = !{!6, !276, !277}
!276 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !74, size: 64)
!277 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !29, size: 64)
!278 = !DILocalVariable(name: "text", arg: 1, scope: !273, file: !3, line: 80, type: !276)
!279 = !DILocation(line: 0, scope: !273)
!280 = !DILocalVariable(name: "word", arg: 2, scope: !273, file: !3, line: 80, type: !277)
!281 = !DILocation(line: 81, column: 21, scope: !273)
!282 = !DILocalVariable(name: "p", scope: !273, file: !3, line: 81, type: !74)
!283 = !DILocation(line: 82, column: 5, scope: !273)
!284 = !DILocation(line: 82, column: 12, scope: !273)
!285 = !DILocation(line: 82, column: 15, scope: !273)
!286 = !DILocation(line: 82, column: 23, scope: !273)
!287 = !DILocation(line: 82, column: 27, scope: !273)
!288 = !DILocation(line: 82, column: 50, scope: !273)
!289 = !DILocation(line: 82, column: 26, scope: !273)
!290 = !DILocation(line: 83, column: 10, scope: !291)
!291 = distinct !DILexicalBlock(scope: !273, file: !3, line: 82, column: 55)
!292 = distinct !{!292, !283, !293, !155}
!293 = !DILocation(line: 84, column: 5, scope: !273)
!294 = !DILocalVariable(name: "length", scope: !273, file: !3, line: 85, type: !6)
!295 = !DILocation(line: 86, column: 5, scope: !273)
!296 = !DILocation(line: 86, column: 12, scope: !273)
!297 = !DILocation(line: 86, column: 35, scope: !273)
!298 = !DILocation(line: 87, column: 20, scope: !299)
!299 = distinct !DILexicalBlock(scope: !300, file: !3, line: 87, column: 13)
!300 = distinct !DILexicalBlock(scope: !273, file: !3, line: 86, column: 40)
!301 = !DILocation(line: 88, column: 59, scope: !302)
!302 = distinct !DILexicalBlock(scope: !299, file: !3, line: 87, column: 36)
!303 = !DILocation(line: 88, column: 44, scope: !302)
!304 = !DILocation(line: 88, column: 36, scope: !302)
!305 = !DILocation(line: 88, column: 30, scope: !302)
!306 = !DILocation(line: 88, column: 24, scope: !302)
!307 = !DILocation(line: 88, column: 13, scope: !302)
!308 = !DILocation(line: 88, column: 28, scope: !302)
!309 = !DILocation(line: 89, column: 9, scope: !302)
!310 = !DILocation(line: 90, column: 10, scope: !300)
!311 = distinct !{!311, !295, !312, !155}
!312 = !DILocation(line: 91, column: 5, scope: !273)
!313 = !DILocation(line: 92, column: 5, scope: !273)
!314 = !DILocation(line: 92, column: 18, scope: !273)
!315 = !DILocation(line: 93, column: 11, scope: !273)
!316 = !DILocation(line: 94, column: 5, scope: !273)
!317 = distinct !DISubprogram(name: "table_add", scope: !3, file: !3, line: 44, type: !318, scopeLine: 44, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!318 = !DISubroutineType(types: !319)
!319 = !{!6, !127, !74, !6}
!320 = !DILocalVariable(name: "table", arg: 1, scope: !317, file: !3, line: 44, type: !127)
!321 = !DILocation(line: 0, scope: !317)
!322 = !DILocalVariable(name: "word", arg: 2, scope: !317, file: !3, line: 44, type: !74)
!323 = !DILocalVariable(name: "position", arg: 3, scope: !317, file: !3, line: 44, type: !6)
!324 = !DILocation(line: 45, column: 26, scope: !317)
!325 = !DILocalVariable(name: "index", scope: !317, file: !3, line: 45, type: !12)
!326 = !DILocalVariable(name: "probe", scope: !327, file: !3, line: 46, type: !6)
!327 = distinct !DILexicalBlock(scope: !317, file: !3, line: 46, column: 5)
!328 = !DILocation(line: 0, scope: !327)
!329 = !DILocation(line: 46, column: 10, scope: !327)
!330 = !DILocation(line: 46, scope: !327)
!331 = !DILocation(line: 46, column: 31, scope: !332)
!332 = distinct !DILexicalBlock(scope: !327, file: !3, line: 46, column: 5)
!333 = !DILocation(line: 46, column: 5, scope: !327)
!334 = !DILocation(line: 47, column: 31, scope: !335)
!335 = distinct !DILexicalBlock(scope: !332, file: !3, line: 46, column: 54)
!336 = !DILocalVariable(name: "slot", scope: !335, file: !3, line: 47, type: !162)
!337 = !DILocation(line: 0, scope: !335)
!338 = !DILocation(line: 48, column: 19, scope: !339)
!339 = distinct !DILexicalBlock(scope: !335, file: !3, line: 48, column: 13)
!340 = !DILocation(line: 48, column: 25, scope: !339)
!341 = !DILocation(line: 49, column: 13, scope: !342)
!342 = distinct !DILexicalBlock(scope: !339, file: !3, line: 48, column: 31)
!343 = !DILocation(line: 50, column: 19, scope: !342)
!344 = !DILocation(line: 50, column: 25, scope: !342)
!345 = !DILocation(line: 51, column: 19, scope: !342)
!346 = !DILocation(line: 51, column: 30, scope: !342)
!347 = !DILocation(line: 52, column: 20, scope: !342)
!348 = !DILocation(line: 52, column: 24, scope: !342)
!349 = !DILocation(line: 53, column: 13, scope: !342)
!350 = !DILocation(line: 55, column: 13, scope: !351)
!351 = distinct !DILexicalBlock(scope: !335, file: !3, line: 55, column: 13)
!352 = !DILocation(line: 55, column: 38, scope: !351)
!353 = !DILocation(line: 56, column: 19, scope: !354)
!354 = distinct !DILexicalBlock(scope: !351, file: !3, line: 55, column: 44)
!355 = !DILocation(line: 56, column: 24, scope: !354)
!356 = !DILocation(line: 57, column: 13, scope: !354)
!357 = !DILocation(line: 59, column: 24, scope: !335)
!358 = !DILocation(line: 46, column: 50, scope: !332)
!359 = !DILocation(line: 46, column: 5, scope: !332)
!360 = distinct !{!360, !333, !361, !155}
!361 = !DILocation(line: 60, column: 5, scope: !327)
!362 = !DILocation(line: 62, column: 1, scope: !317)
!363 = distinct !DISubprogram(name: "hash_word", scope: !3, file: !3, line: 30, type: !364, scopeLine: 30, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!364 = !DISubroutineType(types: !365)
!365 = !{!12, !74}
!366 = !DILocalVariable(name: "word", arg: 1, scope: !363, file: !3, line: 30, type: !74)
!367 = !DILocation(line: 0, scope: !363)
!368 = !DILocalVariable(name: "hash", scope: !363, file: !3, line: 31, type: !12)
!369 = !DILocalVariable(name: "p", scope: !370, file: !3, line: 32, type: !74)
!370 = distinct !DILexicalBlock(scope: !363, file: !3, line: 32, column: 5)
!371 = !DILocation(line: 0, scope: !370)
!372 = !DILocation(line: 32, column: 10, scope: !370)
!373 = !DILocation(line: 32, scope: !370)
!374 = !DILocation(line: 32, column: 32, scope: !375)
!375 = distinct !DILexicalBlock(scope: !370, file: !3, line: 32, column: 5)
!376 = !DILocation(line: 32, column: 35, scope: !375)
!377 = !DILocation(line: 32, column: 5, scope: !370)
!378 = !DILocation(line: 33, column: 32, scope: !379)
!379 = distinct !DILexicalBlock(scope: !375, file: !3, line: 32, column: 49)
!380 = !DILocation(line: 33, column: 17, scope: !379)
!381 = !DILocation(line: 33, column: 14, scope: !379)
!382 = !DILocation(line: 34, column: 14, scope: !379)
!383 = !DILocation(line: 32, column: 45, scope: !375)
!384 = !DILocation(line: 32, column: 5, scope: !375)
!385 = distinct !{!385, !377, !386, !155}
!386 = !DILocation(line: 35, column: 5, scope: !370)
!387 = !DILocation(line: 36, column: 5, scope: !363)
!388 = distinct !DISubprogram(name: "by_count", scope: !3, file: !3, line: 111, type: !389, scopeLine: 111, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!389 = !DISubroutineType(types: !390)
!390 = !{!6, !391, !391}
!391 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !392, size: 64)
!392 = !DIDerivedType(tag: DW_TAG_const_type, baseType: null)
!393 = !DILocalVariable(name: "a", arg: 1, scope: !388, file: !3, line: 111, type: !391)
!394 = !DILocation(line: 0, scope: !388)
!395 = !DILocalVariable(name: "b", arg: 2, scope: !388, file: !3, line: 111, type: !391)
!396 = !DILocalVariable(name: "x", scope: !388, file: !3, line: 112, type: !195)
!397 = !DILocalVariable(name: "y", scope: !388, file: !3, line: 113, type: !195)
!398 = !DILocation(line: 114, column: 12, scope: !399)
!399 = distinct !DILexicalBlock(scope: !388, file: !3, line: 114, column: 9)
!400 = !DILocation(line: 114, column: 24, scope: !399)
!401 = !DILocation(line: 114, column: 18, scope: !399)
!402 = !DILocation(line: 115, column: 19, scope: !403)
!403 = distinct !DILexicalBlock(scope: !399, file: !3, line: 114, column: 31)
!404 = !DILocation(line: 115, column: 30, scope: !403)
!405 = !DILocation(line: 115, column: 25, scope: !403)
!406 = !DILocation(line: 115, column: 9, scope: !403)
!407 = !DILocation(line: 117, column: 15, scope: !388)
!408 = !DILocation(line: 117, column: 31, scope: !388)
!409 = !DILocation(line: 117, column: 26, scope: !388)
!410 = !DILocation(line: 117, column: 5, scope: !388)
!411 = !DILocation(line: 118, column: 1, scope: !388)
!412 = distinct !DISubprogram(name: "print_bar", scope: !3, file: !3, line: 162, type: !413, scopeLine: 162, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!413 = !DISubroutineType(types: !414)
!414 = !{null, !6, !6}
!415 = !DILocalVariable(name: "count", arg: 1, scope: !412, file: !3, line: 162, type: !6)
!416 = !DILocation(line: 0, scope: !412)
!417 = !DILocalVariable(name: "widest", arg: 2, scope: !412, file: !3, line: 162, type: !6)
!418 = !DILocation(line: 163, column: 24, scope: !412)
!419 = !DILocation(line: 163, column: 17, scope: !412)
!420 = !DILocation(line: 163, column: 36, scope: !412)
!421 = !DILocation(line: 163, column: 41, scope: !412)
!422 = !DILocalVariable(name: "width", scope: !412, file: !3, line: 163, type: !6)
!423 = !DILocalVariable(name: "i", scope: !424, file: !3, line: 164, type: !6)
!424 = distinct !DILexicalBlock(scope: !412, file: !3, line: 164, column: 5)
!425 = !DILocation(line: 0, scope: !424)
!426 = !DILocation(line: 164, column: 10, scope: !424)
!427 = !DILocation(line: 164, scope: !424)
!428 = !DILocation(line: 164, column: 23, scope: !429)
!429 = distinct !DILexicalBlock(scope: !424, file: !3, line: 164, column: 5)
!430 = !DILocation(line: 164, column: 5, scope: !424)
!431 = !DILocation(line: 165, column: 9, scope: !432)
!432 = distinct !DILexicalBlock(scope: !429, file: !3, line: 164, column: 37)
!433 = !DILocation(line: 164, column: 33, scope: !429)
!434 = !DILocation(line: 164, column: 5, scope: !429)
!435 = distinct !{!435, !430, !436, !155}
!436 = !DILocation(line: 166, column: 5, scope: !424)
!437 = !DILocation(line: 167, column: 5, scope: !412)
!438 = !DILocation(line: 168, column: 1, scope: !412)
!439 = distinct !DISubprogram(name: "longest", scope: !3, file: !3, line: 141, type: !440, scopeLine: 141, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!440 = !DISubroutineType(types: !441)
!441 = !{!195, !195, !6}
!442 = !DILocalVariable(name: "entries", arg: 1, scope: !439, file: !3, line: 141, type: !195)
!443 = !DILocation(line: 0, scope: !439)
!444 = !DILocalVariable(name: "n", arg: 2, scope: !439, file: !3, line: 141, type: !6)
!445 = !DILocalVariable(name: "best", scope: !439, file: !3, line: 142, type: !195)
!446 = !DILocalVariable(name: "best_length", scope: !439, file: !3, line: 143, type: !30)
!447 = !DILocalVariable(name: "i", scope: !448, file: !3, line: 144, type: !6)
!448 = distinct !DILexicalBlock(scope: !439, file: !3, line: 144, column: 5)
!449 = !DILocation(line: 0, scope: !448)
!450 = !DILocation(line: 144, column: 10, scope: !448)
!451 = !DILocation(line: 144, scope: !448)
!452 = !DILocation(line: 144, column: 23, scope: !453)
!453 = distinct !DILexicalBlock(scope: !448, file: !3, line: 144, column: 5)
!454 = !DILocation(line: 144, column: 5, scope: !448)
!455 = !DILocation(line: 145, column: 32, scope: !456)
!456 = distinct !DILexicalBlock(scope: !453, file: !3, line: 144, column: 33)
!457 = !DILocation(line: 145, column: 25, scope: !456)
!458 = !DILocalVariable(name: "length", scope: !456, file: !3, line: 145, type: !30)
!459 = !DILocation(line: 0, scope: !456)
!460 = !DILocation(line: 146, column: 20, scope: !461)
!461 = distinct !DILexicalBlock(scope: !456, file: !3, line: 146, column: 13)
!462 = !DILocation(line: 144, column: 29, scope: !453)
!463 = !DILocation(line: 144, column: 5, scope: !453)
!464 = distinct !{!464, !454, !465, !155}
!465 = !DILocation(line: 150, column: 5, scope: !448)
!466 = !DILocation(line: 151, column: 5, scope: !439)
!467 = distinct !DISubprogram(name: "mean_length", scope: !3, file: !3, line: 131, type: !468, scopeLine: 131, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!468 = !DISubroutineType(types: !469)
!469 = !{!35, !195, !6}
!470 = !DILocalVariable(name: "entries", arg: 1, scope: !467, file: !3, line: 131, type: !195)
!471 = !DILocation(line: 0, scope: !467)
!472 = !DILocalVariable(name: "n", arg: 2, scope: !467, file: !3, line: 131, type: !6)
!473 = !DILocalVariable(name: "letters", scope: !467, file: !3, line: 132, type: !34)
!474 = !DILocalVariable(name: "words", scope: !467, file: !3, line: 133, type: !34)
!475 = !DILocalVariable(name: "i", scope: !476, file: !3, line: 134, type: !6)
!476 = distinct !DILexicalBlock(scope: !467, file: !3, line: 134, column: 5)
!477 = !DILocation(line: 0, scope: !476)
!478 = !DILocation(line: 134, column: 10, scope: !476)
!479 = !DILocation(line: 134, scope: !476)
!480 = !DILocation(line: 134, column: 23, scope: !481)
!481 = distinct !DILexicalBlock(scope: !476, file: !3, line: 134, column: 5)
!482 = !DILocation(line: 134, column: 5, scope: !476)
!483 = !DILocation(line: 136, column: 18, scope: !484)
!484 = distinct !DILexicalBlock(scope: !481, file: !3, line: 134, column: 33)
!485 = !DILocation(line: 136, column: 29, scope: !484)
!486 = !DILocation(line: 136, column: 15, scope: !484)
!487 = !DILocation(line: 135, column: 33, scope: !484)
!488 = !DILocation(line: 135, column: 26, scope: !484)
!489 = !DILocation(line: 135, column: 52, scope: !484)
!490 = !DILocation(line: 135, column: 63, scope: !484)
!491 = !DILocation(line: 135, column: 50, scope: !484)
!492 = !DILocation(line: 135, column: 17, scope: !484)
!493 = !DILocation(line: 134, column: 29, scope: !481)
!494 = !DILocation(line: 134, column: 5, scope: !481)
!495 = distinct !{!495, !482, !496, !155}
!496 = !DILocation(line: 137, column: 5, scope: !476)
!497 = !DILocation(line: 138, column: 18, scope: !467)
!498 = !DILocation(line: 138, column: 12, scope: !467)
!499 = !DILocation(line: 138, column: 5, scope: !467)
!500 = distinct !DISubprogram(name: "singletons", scope: !3, file: !3, line: 154, type: !501, scopeLine: 154, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !7, retainedNodes: !95)
!501 = !DISubroutineType(types: !502)
!502 = !{!6, !195, !6}
!503 = !DILocalVariable(name: "entries", arg: 1, scope: !500, file: !3, line: 154, type: !195)
!504 = !DILocation(line: 0, scope: !500)
!505 = !DILocalVariable(name: "n", arg: 2, scope: !500, file: !3, line: 154, type: !6)
!506 = !DILocalVariable(name: "count", scope: !500, file: !3, line: 155, type: !6)
!507 = !DILocalVariable(name: "i", scope: !508, file: !3, line: 156, type: !6)
!508 = distinct !DILexicalBlock(scope: !500, file: !3, line: 156, column: 5)
!509 = !DILocation(line: 0, scope: !508)
!510 = !DILocation(line: 156, column: 10, scope: !508)
!511 = !DILocation(line: 156, scope: !508)
!512 = !DILocation(line: 156, column: 27, scope: !513)
!513 = distinct !DILexicalBlock(scope: !508, file: !3, line: 156, column: 5)
!514 = !DILocation(line: 156, column: 32, scope: !513)
!515 = !DILocation(line: 156, column: 35, scope: !513)
!516 = !DILocation(line: 156, column: 46, scope: !513)
!517 = !DILocation(line: 156, column: 52, scope: !513)
!518 = !DILocation(line: 156, column: 5, scope: !508)
!519 = !DILocation(line: 157, column: 14, scope: !520)
!520 = distinct !DILexicalBlock(scope: !513, file: !3, line: 156, column: 63)
!521 = !DILocation(line: 156, column: 5, scope: !513)
!522 = distinct !{!522, !518, !523, !155}
!523 = !DILocation(line: 158, column: 5, scope: !508)
!524 = !DILocation(line: 159, column: 5, scope: !500)
