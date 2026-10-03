program IngridientManager;

uses
  SysUtils;

const
  MAX_ING = 20;
  MAX_REPL = 5;

type
  TIngPair = record
    IngCode: Integer;
    Amount: Double;
  end;

  PIngredient = ^TIngredient;
  TIngredient = record
    Code: Integer;
    Name: string[50];
    Quantity: Double;
    Proteins: Double;
    Fats: Double;
    Carbs: Double;
    Replaces: array[0..MAX_REPL-1] of Integer;
    ReplCount: Integer;
    Next: PIngredient;
  end;

  PSalad = ^TSalad;
  TSalad = record
    Code: Integer;
    Name: string[50];
    Price: Double;
    Ings: array[0..MAX_ING-1] of TIngPair;
    IngCount: Integer;
    Next: PSalad;
  end;

  POrder = ^TOrder;
  TOrder = record
    SaladCode: Integer;
    Portions: Integer;
    CanCook: Boolean;
    Next: POrder;
  end;

var
  GIngList: PIngredient;
  GSalList: PSalad;
  GOrdList: POrder;

procedure Pause;
begin
  WriteLn;
  Write('Нажмите Enter...');
  ReadLn;
end;

function ReadInt(const Msg: string): Integer;
var
  s: string;
  v: Integer;
  c: Integer;
begin
  repeat
    Write(Msg);
    ReadLn(s);
    Val(s, v, c);
    if c <> 0 then WriteLn('Введите целое число!');
  until c = 0;
  Result:= v;
end;

function ReadDbl(const Msg: string): Double;
var
  s: string;
  v: Double;
  c: Integer;
  i: Integer;
begin
  repeat
    Write(Msg);
    ReadLn(s);
    for i:= 1 to Length(s) do
      if s[i] = ',' then s[i]:= '.';
    Val(s, v, c);
    if c <> 0 then WriteLn('Введите число!');
  until c = 0;
  Result:= v;
end;

function FindIng(Code: Integer): PIngredient;
var p: PIngredient;
begin
  Result:= nil;
  p:= GIngList;
  while p <> nil do
  begin
    if p^.Code = Code then begin Result:= p; Exit; end;
    p:= p^.Next;
  end;
end;

procedure AddIng(Code: Integer; const Name: string;
  Qty, Prot, Fat, Carb: Double);
var
  n: PIngredient;
  p: PIngredient;
begin
  New(n);
  n^.Code:= Code;
  n^.Name:= Name;
  n^.Quantity:= Qty;
  n^.Proteins:= Prot;
  n^.Fats:= Fat;
  n^.Carbs:= Carb;
  n^.ReplCount:= 0;
  n^.Next:= nil;
  if GIngList = nil then
    GIngList:= n
  else
  begin
    p:= GIngList;
    while p^.Next <> nil do p:= p^.Next;
    p^.Next:= n;
  end;
end;

function HasRepl(p: PIngredient; Code: Integer): Boolean;
var i: Integer;
begin
  Result:= False;
  for i:= 0 to p^.ReplCount - 1 do
    if p^.Replaces[i] = Code then
    begin
      Result:= True;
      Exit;
    end;
end;

function AddRepl(p: PIngredient; Code: Integer): Boolean;
begin
  Result:= False;
  if p^.ReplCount >= MAX_REPL then Exit;
  if HasRepl(p, Code) then Exit;
  p^.Replaces[p^.ReplCount]:= Code;
  Inc(p^.ReplCount);
  Result:= True;
end;

procedure AddReplByCode(IngCode, ReplCode: Integer);
var p: PIngredient;
begin
  p:= FindIng(IngCode);
  if p <> nil then AddRepl(p, ReplCode);
end;

procedure RemoveReplRefs(Code: Integer);
var
  q: PIngredient;
  i: Integer;
  j: Integer;
begin
  q:= GIngList;
  while q <> nil do
  begin
    i:= 0;
    while i < q^.ReplCount do
    begin
      if q^.Replaces[i] = Code then
      begin
        for j:= i to q^.ReplCount - 2 do
          q^.Replaces[j]:= q^.Replaces[j + 1];
        Dec(q^.ReplCount);
      end
      else
        Inc(i);
    end;
    q:= q^.Next;
  end;
end;

function ReplToStr(p: PIngredient): string;
var i: Integer;
begin
  if p^.ReplCount = 0 then
  begin
    Result:= 'нет';
    Exit;
  end;
  Result:= '';
  for i:= 0 to p^.ReplCount - 1 do
  begin
    if i > 0 then Result:= Result + ', ';
    Result:= Result + IntToStr(p^.Replaces[i]);
  end;
end;

function DelIng(Code: Integer): Boolean;
var
  p: PIngredient;
  prev: PIngredient;
begin
  Result:= False;
  p:= GIngList; prev:= nil;
  while p <> nil do
  begin
    if p^.Code = Code then
    begin
      if prev = nil then GIngList:= p^.Next
      else prev^.Next:= p^.Next;
      Dispose(p);
      RemoveReplRefs(Code);
      Result:= True;
      Exit;
    end;
    prev:= p; p:= p^.Next;
  end;
end;

procedure ShowIng(p: PIngredient);
begin
  WriteLn(' Код:', p^.Code,
          ' Название:', p^.Name,
          ' Кол-во:', p^.Quantity:0:1, 'г',
          ' Б:', p^.Proteins:0:1,
          ' Ж:', p^.Fats:0:1,
          ' У:', p^.Carbs:0:1,
          ' Замены:', ReplToStr(p));
end;

procedure ShowAllIng;
var p: PIngredient;
begin
  if GIngList = nil then begin WriteLn('Список ингредиентов пуст.'); Exit; end;
  WriteLn('=== ИНГРЕДИЕНТЫ ===');
  p:= GIngList;
  while p <> nil do begin ShowIng(p); p:= p^.Next; end;
end;

function FindSal(Code: Integer): PSalad;
var p: PSalad;
begin
  Result:= nil;
  p:= GSalList;
  while p <> nil do
  begin
    if p^.Code = Code then begin Result:= p; Exit; end;
    p:= p^.Next;
  end;
end;

procedure AddSal(Code: Integer; const Name: string; Price: Double);
var
  n: PSalad;
  p: PSalad;
begin
  New(n);
  n^.Code:= Code;
  n^.Name:= Name;
  n^.Price:= Price;
  n^.IngCount:= 0;
  n^.Next:= nil;
  if GSalList = nil then
    GSalList:= n
  else
  begin
    p:= GSalList;
    while p^.Next <> nil do p:= p^.Next;
    p^.Next:= n;
  end;
end;

function DelSal(Code: Integer): Boolean;
var
  p: PSalad;
  prev: PSalad;
begin
  Result:= False;
  p:= GSalList; prev:= nil;
  while p <> nil do
  begin
    if p^.Code = Code then
    begin
      if prev = nil then GSalList:= p^.Next
      else prev^.Next:= p^.Next;
      Dispose(p);
      Result:= True;
      Exit;
    end;
    prev:= p; p:= p^.Next;
  end;
end;

procedure ShowSal(p: PSalad);
var
  i: Integer;
  ing: PIngredient;
begin
  WriteLn(' Код:', p^.Code, ' Название:', p^.Name, ' Цена:', p^.Price:0:2, ' руб.');
  for i:= 0 to p^.IngCount - 1 do
  begin
    ing:= FindIng(p^.Ings[i].IngCode);
    Write(' Ингредиент код:', p^.Ings[i].IngCode);
    if ing <> nil then Write(' (', ing^.Name, ')');
    WriteLn(' - ', p^.Ings[i].Amount:0:1, 'г');
  end;
end;

procedure ShowAllSal;
var p: PSalad;
begin
  if GSalList = nil then begin WriteLn('Список салатов пуст.'); Exit; end;
  WriteLn('=== САЛАТЫ ===');
  p:= GSalList;
  while p <> nil do begin ShowSal(p); p:= p^.Next; end;
end;

function FindOrd(SalCode: Integer): POrder;
var p: POrder;
begin
  Result:= nil;
  p:= GOrdList;
  while p <> nil do
  begin
    if p^.SaladCode = SalCode then begin Result:= p; Exit; end;
    p:= p^.Next;
  end;
end;

procedure AddOrd(SalCode, Portions: Integer);
var
  n: POrder;
  p: POrder;
begin
  New(n);
  n^.SaladCode:= SalCode;
  n^.Portions:= Portions;
  n^.CanCook:= False;
  n^.Next:= nil;
  if GOrdList = nil then
    GOrdList:= n
  else
  begin
    p:= GOrdList;
    while p^.Next <> nil do p:= p^.Next;
    p^.Next:= n;
  end;
end;

function DelOrd(SalCode: Integer): Boolean;

var
  p: POrder;
  prev: POrder;
begin
  Result:= False;
  p:= GOrdList; prev:= nil;
  while p <> nil do
  begin
    if p^.SaladCode = SalCode then
    begin
      if prev = nil then GOrdList:= p^.Next
      else prev^.Next:= p^.Next;
      Dispose(p);
      Result:= True;
      Exit;
    end;
    prev:= p; p:= p^.Next;
  end;
end;

procedure ShowAllOrd;
var
  p: POrder;
  s: PSalad;
begin
  if GOrdList = nil then begin WriteLn('Список заказов пуст.'); Exit; end;
  WriteLn('=== ЗАКАЗЫ НА БАНКЕТ ===');
  p:= GOrdList;
  while p <> nil do
  begin
    s:= FindSal(p^.SaladCode);
    Write(' Код салата:', p^.SaladCode);
    if s <> nil then Write(' (', s^.Name, ')');
    Write(' Порций:', p^.Portions);
    if p^.CanCook then WriteLn(' [МОЖНО]')
    else WriteLn(' [НЕЛЬЗЯ]');
    p:= p^.Next;
  end;
end;

function NextIngCode: Integer;
var
  Code: Integer;
begin
  Code:= 1;

  while FindIng(Code) <> nil do
    Inc(Code);

  Result:= Code;
end;

function NextSalCode: Integer;
var
  Code: Integer;
begin
  Code:= 1;

  while FindSal(Code) <> nil do
    Inc(Code);

  Result:= Code;
end;

function SelectIngredientByName: PIngredient;
var
  mask: string;
  p: PIngredient;
  found: Integer;
  choice: Integer;
  list: array of PIngredient;
  i: Integer;
begin
  Result:= nil;

  Write('Часть названия ингредиента: ');
  ReadLn(mask);

  found:= 0;
  p:= GIngList;

  while p <> nil do
  begin
    if Pos(AnsiLowerCase(mask), AnsiLowerCase(p^.Name)) > 0 then
      Inc(found);

    p:= p^.Next;
  end;

  if found = 0 then
  begin
    WriteLn('Ингредиенты не найдены.');
    Exit;
  end;

  SetLength(list, found);

  p:= GIngList;
  i:= 0;

  while p <> nil do
  begin
    if Pos(AnsiLowerCase(mask), AnsiLowerCase(p^.Name)) > 0 then
    begin
      list[i]:= p;
      Inc(i);
    end;

    p:= p^.Next;
  end;

  WriteLn;
  WriteLn('Найденные ингредиенты:');

  for i:= 0 to found - 1 do
    WriteLn(i + 1, '. ', list[i]^.Name,
            ' (код: ', list[i]^.Code, ')');

  WriteLn;

  choice:= ReadInt('Выберите номер ингредиента: ');

  if (choice < 1) or (choice > found) then
  begin
    WriteLn('Неверный номер.');
    Exit;
  end;

  Result:= list[choice - 1];
end;

function SelectSaladByName: PSalad;
var
  mask: string;
  p: PSalad;
  found: Integer;
  choice: Integer;
  list: array of PSalad;
  i: Integer;
begin
  Result:= nil;

  Write('Часть названия салата: ');
  ReadLn(mask);

  found:= 0;
  p:= GSalList;

  while p <> nil do
  begin
    if Pos(AnsiLowerCase(mask), AnsiLowerCase(p^.Name)) > 0 then
      Inc(found);

    p:= p^.Next;
  end;

  if found = 0 then
  begin
    WriteLn('Салаты не найдены.');
    Exit;
  end;

  SetLength(list, found);

  p:= GSalList;
  i:= 0;

  while p <> nil do
  begin
    if Pos(AnsiLowerCase(mask), AnsiLowerCase(p^.Name)) > 0 then
    begin
      list[i]:= p;
      Inc(i);
    end;

    p:= p^.Next;
  end;

  WriteLn;
  WriteLn('Найденные салаты:');

  for i:= 0 to found - 1 do
    WriteLn(i + 1, '. ', list[i]^.Name,
            ' (код: ', list[i]^.Code, ')');

  WriteLn;

  choice:= ReadInt('Выберите номер салата: ');

  if (choice < 1) or (choice > found) then
  begin
    WriteLn('Неверный номер.');
    Exit;
  end;

  Result:= list[choice - 1];
end;

function SelectOrderByName: POrder;
var
  mask: string;
  p: POrder;
  pS: PSalad;
  found: Integer;
  choice: Integer;
  list: array of POrder;
  i: Integer;
begin
  Result:= nil;

  Write('Часть названия салата в заказе: ');
  ReadLn(mask);

  found:= 0;
  p:= GOrdList;

  while p <> nil do
  begin
    pS:= FindSal(p^.SaladCode);

    if (pS <> nil) and
       (Pos(AnsiLowerCase(mask), AnsiLowerCase(pS^.Name)) > 0) then
      Inc(found);

    p:= p^.Next;
  end;

  if found = 0 then
  begin
    WriteLn('Заказы не найдены.');
    Exit;
  end;

  SetLength(list, found);

  p:= GOrdList;
  i:= 0;

  while p <> nil do
  begin
    pS:= FindSal(p^.SaladCode);

    if (pS <> nil) and
       (Pos(AnsiLowerCase(mask), AnsiLowerCase(pS^.Name)) > 0) then
    begin
      list[i]:= p;
      Inc(i);
    end;

    p:= p^.Next;
  end;

  WriteLn;
  WriteLn('Найденные заказы:');

  for i:= 0 to found - 1 do
  begin
    pS:= FindSal(list[i]^.SaladCode);

    if pS <> nil then
      WriteLn(i + 1, '. ', pS^.Name,
              ' — ', list[i]^.Portions, ' порций',
              ' (код салата: ', list[i]^.SaladCode, ')');
  end;

  WriteLn;

  choice:= ReadInt('Выберите номер заказа: ');

  if (choice < 1) or (choice > found) then
  begin
    WriteLn('Неверный номер.');
    Exit;
  end;

  Result:= list[choice - 1];
end;

procedure InputReplacements(p: PIngredient);
var
  pR: PIngredient;
  s: string;
begin
  p^.ReplCount:= 0;
  WriteLn('Заменители выбираются по названию, по приоритету (максимум ',
          MAX_REPL, ').');

  while p^.ReplCount < MAX_REPL do
  begin
    Write('Добавить заменитель ', p^.ReplCount + 1, '? (д/н): ');
    ReadLn(s);

    if (s <> 'д') and (s <> 'Д') then
      Break;

    pR:= SelectIngredientByName;

    if pR = nil then
      Continue;

    if pR^.Code = p^.Code then
      WriteLn('Ингредиент не может заменять сам себя!')
    else if HasRepl(p, pR^.Code) then
      WriteLn('Этот заменитель уже добавлен.')
    else
    begin
      AddRepl(p, pR^.Code);
      WriteLn('Добавлен заменитель: ', pR^.Name, ' (код: ', pR^.Code, ')');
    end;
  end;

  if p^.ReplCount >= MAX_REPL then
    WriteLn('Достигнут максимум заменителей (', MAX_REPL, ').');
end;

procedure DoAddIng;
var
  code: Integer;
  name: string;
  qty: Double;
  prot: Double;
  fat: Double;
  carb: Double;
  p: PIngredient;
begin
  code:= NextIngCode;

  WriteLn('Автоматически выбран код ингредиента: ', code);

  Write('Название: ');
  ReadLn(name);

  qty:= ReadDbl('Количество (г): ');
  prot:= ReadDbl('Белки (на 100г): ');
  fat:= ReadDbl('Жиры (на 100г): ');
  carb:= ReadDbl('Углеводы (на 100г): ');

  AddIng(code, name, qty, prot, fat, carb);

  p:= FindIng(code);
  if p <> nil then
    InputReplacements(p);

  WriteLn('Добавлено.');
end;

procedure DoAddSal;
var
  code: Integer;
  name: string;
  price: Double;
  cnt: Integer;
  k: Integer;
  pS: PSalad;
  pIng: PIngredient;
begin
  code:= NextSalCode;

  WriteLn('Автоматически выбран код салата: ', code);

  Write('Название: ');
  ReadLn(name);

  price:= ReadDbl('Стоимость одной порции (руб.): ');

  AddSal(code, name, price);

  pS:= FindSal(code);

  cnt:= ReadInt('Количество ингредиентов: ');

  if cnt < 0 then
    cnt:= 0;

  if cnt > MAX_ING then
    cnt:= MAX_ING;

  pS^.IngCount:= cnt;

  for k:= 0 to cnt - 1 do
  begin
    WriteLn;
    WriteLn('Ингредиент ', k + 1, ':');

    pIng:= SelectIngredientByName;

    if pIng = nil then
    begin
      WriteLn('Ингредиент не выбран.');
      pS^.IngCount:= k;
      Exit;
    end;

    pS^.Ings[k].IngCode:= pIng^.Code;

    pS^.Ings[k].Amount:=
      ReadDbl(' Кол-во (г): ');

    WriteLn('Выбран: ', pIng^.Name,
            ' (код: ', pIng^.Code, ')');
  end;

  WriteLn;
  WriteLn('Салат добавлен.');
end;

procedure DoAddOrd;
var
  pS: PSalad;
  port: Integer;
begin
  pS:= SelectSaladByName;

  if pS = nil then
    Exit;

  port:= ReadInt('Количество порций: ');

  AddOrd(pS^.Code, port);

  WriteLn('Добавлено.');
end;

procedure DoDelIng;
var
  p: PIngredient;
  code: Integer;
begin
  p:= SelectIngredientByName;

  if p = nil then
    Exit;

  code:= p^.Code;

  if DelIng(code) then
    WriteLn('Ингредиент удалён.')
  else
    WriteLn('Не удалось удалить ингредиент.');
end;

procedure DoDelSal;
var
  p: PSalad;
  code: Integer;
begin
  p:= SelectSaladByName;

  if p = nil then
    Exit;

  code:= p^.Code;

  if DelSal(code) then
    WriteLn('Салат удалён.')
  else
    WriteLn('Не удалось удалить салат.');
end;

procedure DoDelOrd;
var
  p: POrder;
  pS: PSalad;
  code: Integer;
begin
  p:= SelectOrderByName;

  if p = nil then
    Exit;

  code:= p^.SaladCode;
  pS:= FindSal(code);

  if DelOrd(code) then
  begin
    if pS <> nil then
      WriteLn('Заказ салата "', pS^.Name, '" удалён.')
    else
      WriteLn('Заказ удалён.');
  end
  else
    WriteLn('Не удалось удалить заказ.');
end;

procedure DoEditIng;
var
  p: PIngredient;
  s: string;
  vd: Double;
  vc: Integer;
begin
  p:= SelectIngredientByName;

  if p = nil then
    Exit;

  ShowIng(p);

  WriteLn;
  WriteLn('Новые значения (Enter = не менять):');

  Write('Название [', p^.Name, ']: ');
  ReadLn(s);
  if s <> '' then
    p^.Name:= s;

  Write('Количество [', p^.Quantity:0:1, ']: ');
  ReadLn(s);
  if s <> '' then
  begin
    Val(s, vd, vc);
    if vc = 0 then
      p^.Quantity:= vd;
  end;

  Write('Белки [', p^.Proteins:0:1, ']: ');
  ReadLn(s);
  if s <> '' then
  begin
    Val(s, vd, vc);
    if vc = 0 then
      p^.Proteins:= vd;
  end;

  Write('Жиры [', p^.Fats:0:1, ']: ');
  ReadLn(s);
  if s <> '' then
  begin
    Val(s, vd, vc);
    if vc = 0 then
      p^.Fats:= vd;
  end;

  Write('Углеводы [', p^.Carbs:0:1, ']: ');
  ReadLn(s);
  if s <> '' then
  begin
    Val(s, vd, vc);
    if vc = 0 then
      p^.Carbs:= vd;
  end;

  WriteLn('Текущие заменители: ', ReplToStr(p));
  Write('Изменить заменители? (д/н): ');
  ReadLn(s);

  if (s = 'д') or (s = 'Д') then
    InputReplacements(p);

  WriteLn('Сохранено.');
end;

procedure DoEditSal;
var
  p: PSalad;
  pIng: PIngredient;
  s: string;
  cnt: Integer;
  k: Integer;
  vc: Integer;
  vd: Double;
begin
  p:= SelectSaladByName;

  if p = nil then
    Exit;

  ShowSal(p);

  WriteLn;

  Write('Новое название [', p^.Name, ']: ');
  ReadLn(s);

  if s <> '' then
    p^.Name:= s;

  Write('Новая стоимость порции [', p^.Price:0:2, ']: ');
  ReadLn(s);

  if s <> '' then
  begin
    Val(s, vd, vc);
    if vc = 0 then
      p^.Price:= vd
    else
      WriteLn('Некорректная стоимость. Цена не изменена.');
  end;

  Write('Изменить ингредиенты? (д/н): ');
  ReadLn(s);

  if (s = 'д') or (s = 'Д') then
  begin
    cnt:= ReadInt('Количество ингредиентов: ');

    if cnt < 0 then
      cnt:= 0;

    if cnt > MAX_ING then
      cnt:= MAX_ING;

    p^.IngCount:= cnt;

    for k:= 0 to cnt - 1 do
    begin
      WriteLn;
      WriteLn('Ингредиент ', k + 1, ':');

      pIng:= SelectIngredientByName;

      if pIng = nil then
      begin
        WriteLn('Ингредиент не выбран.');
        p^.IngCount:= k;
        Exit;
      end;

      p^.Ings[k].IngCode:= pIng^.Code;

      p^.Ings[k].Amount:=
        ReadDbl(' Кол-во (г): ');

      WriteLn('Выбран: ', pIng^.Name,
              ' (код: ', pIng^.Code, ')');
    end;
  end;

  WriteLn('Сохранено.');
end;

procedure DoEditOrd;
var
  p: POrder;
  pS: PSalad;
begin
  p:= SelectOrderByName;

  if p = nil then
    Exit;

  pS:= FindSal(p^.SaladCode);

  if pS <> nil then
    WriteLn('Салат: ', pS^.Name);

  WriteLn('Текущее количество порций: ', p^.Portions);

  p^.Portions:=
    ReadInt('Новое количество порций: ');

  WriteLn('Сохранено.');
end;

procedure FillDemo;
var pS: PSalad;
begin
  if (GIngList <> nil) or (GSalList <> nil) or (GOrdList <> nil) then Exit;
  WriteLn('Загружаю демо-данные...');
  AddIng(1, 'Помидоры', 5000, 0.9, 0.2, 3.9);
  AddIng(2, 'Огурцы', 3000, 0.8, 0.1, 2.8);
  AddIng(3, 'Сыр Фета', 2000, 17.0, 21.0, 0.5);
  AddIng(4, 'Сыр Моцарелла', 1000, 18.0, 19.0, 0.6);
  AddIng(5, 'Листья салата', 1500, 1.2, 0.2, 1.8);
  AddIng(6, 'Оливковое масло', 500, 0.0, 99.8, 0.0);
  AddIng(7, 'Подсолнечное масло', 500, 0.0, 99.9, 0.0);
  AddIng(8, 'Куриное филе', 4000, 23.0, 1.5, 0.0);
  AddIng(9, 'Индейка', 2000, 21.5, 2.0, 0.0);
  AddIng(10, 'Сухарики', 800, 11.0, 5.0, 70.0);
  AddIng(11, 'Пармезан', 500, 33.0, 28.0, 3.0);
  AddIng(12, 'Яйца', 1200, 13.0, 11.0, 0.7);

  AddReplByCode(3, 4);
  AddReplByCode(3, 11);
  AddReplByCode(6, 7);
  AddReplByCode(8, 9);

  AddSal(1, 'Греческий', 350.00);
  pS:= FindSal(1);
  pS^.IngCount:= 4;
  pS^.Ings[0].IngCode:= 1; pS^.Ings[0].Amount:= 100;
  pS^.Ings[1].IngCode:= 2; pS^.Ings[1].Amount:= 80;
  pS^.Ings[2].IngCode:= 3; pS^.Ings[2].Amount:= 60;
  pS^.Ings[3].IngCode:= 6; pS^.Ings[3].Amount:= 15;

  AddSal(2, 'Цезарь', 420.00);
  pS:= FindSal(2);
  pS^.IngCount:= 5;
  pS^.Ings[0].IngCode:= 5; pS^.Ings[0].Amount:= 80;
  pS^.Ings[1].IngCode:= 8; pS^.Ings[1].Amount:= 120;
  pS^.Ings[2].IngCode:= 10; pS^.Ings[2].Amount:= 20;
  pS^.Ings[3].IngCode:= 11; pS^.Ings[3].Amount:= 15;
  pS^.Ings[4].IngCode:= 12; pS^.Ings[4].Amount:= 50;

  AddSal(3, 'Капрезе', 390.00);
  pS:= FindSal(3);
  pS^.IngCount:= 3;
  pS^.Ings[0].IngCode:= 1; pS^.Ings[0].Amount:= 120;
  pS^.Ings[1].IngCode:= 4; pS^.Ings[1].Amount:= 100;
  pS^.Ings[2].IngCode:= 6; pS^.Ings[2].Amount:= 10;

  AddOrd(1, 10);
  AddOrd(2, 8);
  AddOrd(3, 5);
  WriteLn('Демо-данные загружены.');
end;

var
  ch: Integer;
  run: Boolean;

begin
  GIngList:= nil;
  GSalList:= nil;
  GOrdList:= nil;
  run:= True;

  WriteLn('==========================================');
  WriteLn(' УПРАВЛЕНИЕ САЛАТАМИ РЕСТОРАНА');
  WriteLn('==========================================');
  try
  FillDemo;

  while run do
  begin
    WriteLn;
    WriteLn('======= ГЛАВНОЕ МЕНЮ =======');
    WriteLn(' 1. Чтение из файлов');
    WriteLn(' 2. Просмотр списков');
    WriteLn(' 3. Сортировка');
    WriteLn(' 4. Поиск');
    WriteLn(' 5. Добавление');
    WriteLn(' 6. Удаление');
    WriteLn(' 7. Редактирование');
    WriteLn(' 8. Анализ заказов');
    WriteLn(' 9. Выход БЕЗ сохранения');
    WriteLn('10. Выход С сохранением');
    WriteLn('============================');
    ch:= ReadInt('Выбор: ');
    case ch of
      2:
        begin
          WriteLn(' 1-Ингредиенты 2-Салаты 3-Заказы');
          case ReadInt('Выбор: ') of
            1: ShowAllIng;
            2: ShowAllSal;
            3: ShowAllOrd;
          else WriteLn('Неверно.');
          end;
          Pause;
        end;
      5:
        begin
          WriteLn(' 1-Ингредиент 2-Салат 3-Заказ');
          case ReadInt('Выбор: ') of
            1: DoAddIng;
            2: DoAddSal;
            3: DoAddOrd;
          else WriteLn('Неверно.');
          end;
          Pause;
        end;
      6:
        begin
          WriteLn(' 1-Ингредиент 2-Салат 3-Заказ');
          case ReadInt('Выбор: ') of
            1: DoDelIng;
            2: DoDelSal;
            3: DoDelOrd;
          else WriteLn('Неверно.');
          end;
          Pause;
        end;
      7:
        begin
          WriteLn(' 1-Ингредиент 2-Салат 3-Заказ');
          case ReadInt('Выбор: ') of
            1: DoEditIng;
            2: DoEditSal;
            3: DoEditOrd;
          else WriteLn('Неверно.');
          end;
          Pause;
        end;
      9:
        begin
          WriteLn('Выход без сохранения.');
          run:= False;
        end;
    else
      WriteLn('Неверный пункт меню.');
    end;
  end;
  except
    on E: Exception do
    begin
      WriteLn;
      WriteLn('Ошибка: ', E.Message);
      Pause;
    end;
  end;
end.
