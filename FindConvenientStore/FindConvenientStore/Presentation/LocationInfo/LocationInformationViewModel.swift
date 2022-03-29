//
//  LocationInformationViewModel.swift
//  FindConvenientStore
//
//  Created by 장선영 on 2022/03/08.
//

import Foundation
import RxSwift
import RxCocoa

struct LocationInformationViewModel {
    let disposebag = DisposeBag()
    
    //subViewModels
    let detailListBackgroundViewModel = DetailListBackgroundViewModel()
    
    // viewModel -> view
    let setMapCenter: Signal<MTMapPoint>
    let errorMessage: Signal<String>
    let detailListCellData : Driver<[DetailListCellData]>
    let scrollToSelectedLocation : Signal<Int>
    
    // view -> viewModel
    let currentLocation = PublishRelay<MTMapPoint>()
    let mapCenterPoint = PublishRelay<MTMapPoint>()
    let selectPOIItem = PublishRelay<MTMapPOIItem>()
    let mapViewError = PublishRelay<String>()
    let currentLocationButtonTapped = PublishRelay<Void>()
    let detailListItemSelected = PublishRelay<Int>()

    private let documentData = PublishSubject<[KLDocument]>()
        
    init(model: LocationInfromationModel = LocationInfromationModel()) {
        // MARK : network 통신하여 데이터 불러오기
        let cvsLocationDataResult = mapCenterPoint
            .flatMapLatest(model.getLocation)
            .share()
        
        let cvsLocationDataValue = cvsLocationDataResult
            .compactMap { data -> LocationData? in
                guard case let .success(value) = data else {
                    return nil
                }
                return value
            }
        
        let cvsLocationDataErrorMessage = cvsLocationDataResult
            .compactMap { data -> String? in
                switch data {
                case let .success(data) where data.documents.isEmpty:
                    return """
                        500m 근처에 이용할 수 있는 편의점이 없어요.
                        지도 위치를 옮겨서 재검색 해주세요.
                        """
                case let .failure(err):
                    return err.localizedDescription
                default:
                    return nil
                }
            }
        
        cvsLocationDataValue
            .map { $0.documents }
            .bind(to: documentData)
            .disposed(by: disposebag)
        
        // MARK : 지도 중심점 설정
        let selectDetailListItem = detailListItemSelected
            .withLatestFrom(documentData) { $1[$0] }
            .map{ data -> MTMapPoint in
                guard let longitude = Double(data.x),
                      let latitude = Double(data.y) else {
                    return MTMapPoint()
                }
                let geoCoord = MTMapPointGeo(latitude: latitude, longitude: longitude)
                return MTMapPoint(geoCoord: geoCoord)
            }
        
        let moveToCurrentLocation = currentLocationButtonTapped
            .withLatestFrom(currentLocation)
        
        let currentMapCenter = Observable
            .merge(
                currentLocation.take(1),
                   selectDetailListItem,
                   moveToCurrentLocation
                )
        
        setMapCenter = currentMapCenter
            .asSignal(onErrorSignalWith: .empty())
        
        errorMessage = Observable
            .merge(
                cvsLocationDataErrorMessage,
                mapViewError.asObservable()
            )
            .asSignal(onErrorJustReturn: "잠시 후 다시 시도해주세요.")
        
        detailListCellData = documentData
            .map(model.documentsToCellData(_:))
            .asDriver(onErrorDriveWith: .empty())
        
        documentData
            .map{ !$0.isEmpty }
            .bind(to: detailListBackgroundViewModel.shouldHideStatusLabel)
            .disposed(by: disposebag)
        
        scrollToSelectedLocation = selectPOIItem
            .map { $0.tag }
            .asSignal(onErrorJustReturn: 0)
    }
}
